# Logic App Standard — Storage File Share 403 Forbidden: Full Troubleshooting Guide

**Environment:** Azure Logic App Standard + Terraform AzureRM Provider v4.x  
**Symptom:** `Creation of storage file share failed with: 'The remote server returned an error: (403) Forbidden.'`  
**Resource:** `module.logic_app.azurerm_logic_app_standard.logic_app`

---

## What Is Happening (Background)

When Azure provisions a **Logic App Standard** resource, it does the following automatically **before** the Logic App is fully running:

1. Connects to the linked storage account using the **account name + access key** you provide.
2. Creates internal Azure File Shares (e.g. `la-<name>-content`) to store workflow definitions, host configuration, and runtime state.
3. This provisioning call comes from **Azure's App Service management infrastructure**, which runs **outside your VNet** on Microsoft's backend IP ranges.

If anything blocks that call — network rules, missing keys, or policy — you get HTTP 403 Forbidden and the Logic App creation fails completely.

---

## Attempt 1 — Storage Account with `public_network_access_enabled = false`

### Terraform Config

```hcl
resource "azurerm_storage_account" "main" {
  public_network_access_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```

### Error

```
Creation of storage file share failed with:
'The remote server returned an error: (403) Forbidden.'
```

### Why It Failed

Setting `public_network_access_enabled = false` **completely disables the public endpoint** — even the `bypass = ["AzureServices"]` setting is ignored when the public endpoint itself is off. The `bypass` list only operates when the public endpoint is active and `default_action = "Deny"` is filtering traffic. With the endpoint off, there is nothing to bypass through.

### Lesson

> `bypass = ["AzureServices"]` does NOT work when `public_network_access_enabled = false`.  
> These two settings are independent controls. The bypass only applies to traffic allowed through the public endpoint.

---

## Attempt 2 — Public Access Enabled + AzureServices Bypass

### Terraform Config

```hcl
resource "azurerm_storage_account" "main" {
  public_network_access_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```

### Error

```
Creation of storage file share failed with:
'The remote server returned an error: (403) Forbidden.'
```

### Why It Failed

The `bypass = ["AzureServices"]` applies only to a **specific Microsoft trusted-services list**. Azure App Service (which runs the Logic App Standard provisioning agent) is **not on that list**.

**Azure Storage trusted services list (does NOT include App Service):**
- Azure Backup
- Azure Data Box
- Azure Event Grid / Event Hubs
- Azure HDInsight
- Azure IoT Hub
- Azure Key Vault
- Azure Machine Learning
- Azure Monitor
- Azure Security Center / Sentinel
- Azure Site Recovery
- Azure SQL / Synapse

App Service, Logic Apps, Functions — **none of these are trusted services** for the storage bypass. The provisioning agent's IP is not whitelisted, so `default_action = "Deny"` blocks it regardless of the bypass setting.

### Lesson

> Do not assume `bypass = ["AzureServices"]` covers all Azure products.  
> Check the [official trusted services list](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security#trusted-microsoft-services) before relying on it.  
> App Service / Logic App Standard is NOT on the list.

---

## Attempt 3 — Logic App Subnet Service Endpoint + Subnet Whitelist

### Terraform Config

```hcl
# In network module — add service endpoint to Logic App subnet
resource "azurerm_subnet" "logic_app" {
  service_endpoints = ["Microsoft.Storage"]
  ...
}

# In storage module — whitelist the Logic App subnet
resource "azurerm_storage_account" "main" {
  public_network_access_enabled = true

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.logic_app_subnet_id]
  }
}
```

### Error

```
Creation of storage file share failed with:
'The remote server returned an error: (403) Forbidden.'
```

### Why It Failed

The **Logic App subnet whitelist** only allows traffic originating **from the Logic App's VNet integration subnet at runtime**. The file share creation during provisioning comes from **Azure's App Service management cluster** — a completely separate set of Microsoft infrastructure IPs that are outside the VNet. The subnet whitelist does not cover those IPs.

Additionally, the `service_endpoints = ["Microsoft.Storage"]` on the subnet is a declaration that the subnet can reach storage via the service endpoint path. But the provisioning agent is not in the subnet — it is in Microsoft's infrastructure. So this has no effect on the provisioning-time 403.

### Lesson

> Subnet service endpoint whitelisting in `network_rules.virtual_network_subnet_ids` only  
> covers **traffic from within that subnet at runtime**.  
> It does NOT cover Azure's provisioning/management plane traffic, which comes from  
> external Microsoft infrastructure IPs during resource creation.

---

## Attempt 4 — Remove `network_rules` Block Entirely

### Terraform Config

```hcl
resource "azurerm_storage_account" "main" {
  public_network_access_enabled = true
  # network_rules block omitted
}
```

### Error

```
Creation of storage file share failed with:
'The remote server returned an error: (403) Forbidden.'
```

### Why It Failed

The storage account **already existed in Azure** from a previous failed apply run with `default_action = "Deny"`. When you **omit** the `network_rules` block in Terraform, the AzureRM provider may not send an explicit API update to reset the existing deny rule on the storage account. Azure retains the previously configured deny rule, and the provisioning agent still gets blocked.

This is a Terraform provider behavior: omitting an optional block on an **existing resource** does not always trigger a destructive update to clear the prior configuration — it depends on whether the provider treats the attribute as computed or explicitly managed.

### Lesson

> Removing an optional block from Terraform config does **not guarantee** Azure's  
> existing configuration is cleared.  
> For existing resources, you must **explicitly set the desired value** to force a  
> provider API call. For network_rules, use `default_action = "Allow"` explicitly.

---

## Final Solution — What Actually Works

### Root Cause Summary

The Logic App Standard provisioning agent runs on Microsoft's App Service infrastructure, which is **external to your VNet and not on the AzureServices trusted-bypass list**. Any `network_rules` block with `default_action = "Deny"` will block the file share creation, regardless of bypass or subnet settings.

Additionally, `shared_access_key_enabled` must be explicitly set to `true` because Logic App Standard authenticates to storage using **name + access key only** (not managed identity for provisioning). If an Azure Policy disables shared keys, or if the attribute defaults off, the key-based call returns 403.

### Working Terraform Config

```hcl
resource "azurerm_storage_account" "main" {
  name                            = var.storage_account_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = local.sku_parts[0]
  account_replication_type        = local.sku_parts[1]
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Must be explicitly true — Logic App Standard provisioning uses name + access
  # key to create internal file shares. If disabled by policy or left unset,
  # the key-based call returns 403 regardless of network configuration.
  shared_access_key_enabled = true

  tags = var.tags

  # default_action = "Allow" is set EXPLICITLY (not omitted) to force Terraform
  # to push an API update on an existing storage account that may have had
  # default_action = "Deny" from a previous apply run. Omitting the block does
  # not clear a pre-existing deny rule in Azure.
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices", "Logging", "Metrics"]
  }
}
```

### Why Each Setting Matters

| Setting | Why It Is Required |
|---|---|
| `shared_access_key_enabled = true` | Logic App Standard provisioning uses name + key authentication. 403 if keys are disabled. |
| `network_rules.default_action = "Allow"` | Explicitly opens the existing storage account. Omitting does not reset a pre-existing Deny rule. |
| `bypass = ["AzureServices", "Logging", "Metrics"]` | Allows Azure Monitor agents (logging/metrics) and any trusted Azure services to access storage. |
| `https_traffic_only_enabled = true` | Enforces TLS — blocks unencrypted HTTP connections. |
| `allow_nested_items_to_be_public = false` | Prevents blobs from being made publicly accessible. |

---

## Why This Is Still Secure

Opening `default_action = "Allow"` does not expose your data to the internet uncontrolled. The following controls remain in place:

| Control Layer | What It Does |
|---|---|
| **Private Endpoints** (blob, table, queue, file) | Logic App runtime traffic resolves storage to a private IP via private DNS zones. It never travels over the public internet. |
| **Private DNS Zones** | `privatelink.blob.core.windows.net` etc. are linked to the spoke VNet, ensuring all internal clients resolve to `10.x.x.x` addresses. |
| **NSGs** | Subnet-to-subnet traffic controlled: app rules at priority 500–510, corporate DenyAllInbound at 1100. |
| **Palo Alto Firewall** | All outbound traffic from the VNet is routed through the Palo Alto FW as the next hop. |
| `https_traffic_only_enabled = true` | No plain HTTP connections accepted. |
| `allow_nested_items_to_be_public = false` | No blob-level public access. |

---

## Decision Tree for Future Storage 403 Errors on Logic App Standard

```
Logic App file share creation → 403 Forbidden
│
├── Is public_network_access_enabled = false?
│     YES → Change to true. The bypass cannot work with the endpoint off.
│
├── Is network_rules.default_action = "Deny"?
│     YES → App Service provisioning is NOT on the AzureServices bypass list.
│           Set default_action = "Allow". Use private endpoints for runtime security.
│
├── Is shared_access_key_enabled = false?
│     YES → Logic App Standard requires access key auth for provisioning.
│           Set shared_access_key_enabled = true or check Azure Policy.
│
├── Was the storage account created in a previous failed apply?
│     YES → Omitting network_rules does not clear the old deny rule.
│           Explicitly set network_rules { default_action = "Allow" }.
│
└── All of the above look fine but still 403?
      → Check Azure Policy assignments:
        az policy assignment list --scope /subscriptions/<id> -o table
        Look for policies enforcing storage key disablement or deny rules.
```

---

## Key Takeaways

1. **Logic App Standard provisioning is NOT a trusted Azure service** for storage network bypass. `bypass = ["AzureServices"]` does not help.
2. **`public_network_access_enabled = false` disables bypass entirely.** Turn it on if provisioning needs to create file shares.
3. **Omitting `network_rules` in Terraform does not clear existing deny rules in Azure.** Always set `default_action` explicitly on existing resources.
4. **`shared_access_key_enabled = true` must be explicit** if there is any chance Azure Policy has touched the storage account.
5. **Security does not depend on the storage network rules alone.** Private endpoints, private DNS, NSGs, and the firewall provide defence-in-depth at the network layer.
