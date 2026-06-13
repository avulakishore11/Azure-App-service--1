# Security Review & Engineering Procedures

## Infrastructure Automation — Terraform on Azure

---

## Document Control

| Field | Details |
|---|---|
| **Document Title** | Security Review & Engineering Procedures |
| **Project** | vm-ss-automation |
| **Author** | Kishore Avula — Corporate IT, Cloud Infrastructure |
| **Audience** | Security Team, Cloud Platform Owners, Audit |
| **Date** | 2026-06-12 |
| **Classification** | Internal — Confidential |

---

## 1. Overview

This document describes the security architecture, controls, and engineering procedures used in the Terraform-based infrastructure automation project for Azure. It is intended to support the security team's review prior to formal organizational adoption.

The project provisions a standardized Azure infrastructure stack via reusable Terraform modules. All security decisions documented here are intentional and enforced in code — not dependent on manual configuration.

---

## 2. Security Architecture Summary

```
Internet
   │
   ▼
[Azure Subscription]
   │
   ├── Resource Group (CanNotDelete lock applied)
   │     │
   │     ├── VNet  10.x.0.0/16
   │     │     ├── logic-app-subnet  /24  (Logic App Standard, VNet-integrated)
   │     │     ├── vm-subnet         /24  (Windows VM — no public IP)
   │     │     └── pe-subnet         /24  (Private Endpoints only)
   │     │
   │     ├── Storage Account         (public access DISABLED — PE only)
   │     ├── Logic App Standard      (VNet-integrated, no public inbound)
   │     ├── Windows VM              (private subnet, no public IP)
   │     ├── Azure Managed Redis     (Entra ID only, PE only, TLS 1.2 minimum)
   │     ├── Log Analytics Workspace (all resource logs/metrics forwarded here)
   │     └── Application Insights    (linked to Logic App)
   │
   └── Subscription-level
         ├── Azure Policy Assignments (required tag enforcement)
         └── Private DNS Zones (5 zones — blob, table, queue, file, Redis)
```

---

## 3. Identity & Access Management

### 3.1 Authentication Approach — Managed Identity (Zero Secrets)

The project uses **User-Assigned Managed Identity (UAMI)** wherever possible. This eliminates the need for storing credentials, connection strings, or access keys in code or configuration.

| Service | Authentication Method | Notes |
|---|---|---|
| Logic App → Storage Account | Managed Identity (UAMI) | No storage access keys used |
| Logic App → Redis | Entra ID via Access Policy Assignment | No access keys; key-based auth **Disabled** |
| VM → Azure Resources | UAMI with `Virtual Machine Contributor` RBAC | Scoped to VM only |
| Terraform → Azure | Azure CLI / Service Principal | Operator authenticates via `az login` or CI/CD SP |

### 3.2 Role Assignments

| Principal | Role | Scope | Provisioned By |
|---|---|---|---|
| Logic App System Identity | Virtual Machine Contributor | Single VM resource | Terraform (`azurerm_role_assignment`) |
| UAMI | Redis Data-Plane Access Policy | Redis database | Terraform (`azapi_resource`) |

### 3.3 Principle of Least Privilege

- The UAMI is scoped to the **minimum required permissions** — `Virtual Machine Contributor` on the specific VM only, not the resource group or subscription
- Redis access uses the built-in `default` data-plane policy — no administrative plane access granted
- No service accounts, shared credentials, or standing privileged access configured

---

## 4. Network Security

### 4.1 Subnet Segmentation

The VNet is divided into three purpose-specific subnets with no cross-subnet routing unless explicitly required:

| Subnet | CIDR | Purpose | Restrictions |
|---|---|---|---|
| `logic-app-subnet` | /24 | Logic App Standard VNet integration | Delegated to `Microsoft.Web/serverFarms`; outbound only |
| `vm-subnet` | /24 | Windows VM | NSG applied; no public IP on VM |
| `pe-subnet` | /24 | Private Endpoints for all PaaS | No other resource types; `privateEndpointNetworkPolicies` disabled |

### 4.2 Network Security Group (NSG)

An NSG is attached to the VM subnet. The default rules are:

- **Deny all inbound** from Internet
- **Allow inbound** from VNet (internal traffic only)
- **Allow outbound** to Internet (for Windows Update, etc.)

NSG is managed by Terraform and any rule changes are tracked in Git.

### 4.3 Private Endpoints

All PaaS services have **public network access disabled**. Access is only possible through private endpoints within the VNet:

| Service | Private Endpoint | DNS Zone |
|---|---|---|
| Storage — Blob | `pe-blob-{storage-name}` | `privatelink.blob.core.windows.net` |
| Storage — Table | `pe-table-{storage-name}` | `privatelink.table.core.windows.net` |
| Storage — Queue | `pe-queue-{storage-name}` | `privatelink.queue.core.windows.net` |
| Storage — File | `pe-file-{storage-name}` | `privatelink.file.core.windows.net` |
| Azure Managed Redis | `pe-redis-{redis-name}` | `privatelink.{region}.redis.azure.net` |

### 4.4 Private DNS Zones

Five private DNS zones are provisioned and linked to the VNet. This ensures that private endpoint FQDNs resolve to private IP addresses — not public ones — for all traffic originating inside the VNet.

---

## 5. Data Security

### 5.1 Encryption

| Layer | Encryption | Notes |
|---|---|---|
| Data at rest — Storage | AES-256 (Microsoft-managed keys) | Azure default; always on |
| Data in transit — Storage | TLS 1.2 minimum | Enforced by Storage Account configuration |
| Data in transit — Redis | TLS 1.2 minimum (`minimumTlsVersion = "1.2"`) | Enforced in Terraform; client protocol set to `Encrypted` |
| VM OS disk | Azure Disk Encryption (platform-managed) | Azure default |

### 5.2 Redis-Specific Security

Azure Managed Redis is configured with the following security controls enforced in Terraform code:

| Control | Setting | Reason |
|---|---|---|
| Access keys | **Disabled** (`accessKeysAuthentication = "Disabled"`) | Entra ID only — no shared secrets |
| Client protocol | **Encrypted** (TLS required) | No plaintext connections allowed |
| Minimum TLS version | **1.2** | Legacy TLS versions rejected |
| Eviction policy | **NoEviction** | Sessions cannot be silently dropped; alerts trigger on memory pressure |
| Persistence (AOF/RDB) | **Disabled** | No data persisted to disk for this use case |
| High availability | **Enabled** | Zone-redundant replica pair |
| Network access | **Private Endpoint only** | No public endpoint |

### 5.3 Storage Security

| Control | Setting |
|---|---|
| Public blob access | Disabled |
| Minimum TLS version | TLS 1.2 |
| Network access | Private Endpoints only |
| Authentication | Managed Identity (no access keys used by application) |

---

## 6. Secrets Management

### 6.1 Current State

| Secret Type | Where It Lives | Risk Level |
|---|---|---|
| VM admin password | `environment/*.tfvars` — excluded from Git via `.gitignore` | Medium — operator must manage manually |
| Azure Subscription ID | `variables.tf` default / `tfvars` | Low — not a secret; subscription IDs are not sensitive credentials |
| Redis connection | Not stored anywhere — derived at runtime via Managed Identity | None |
| Storage access keys | Not used by application — Managed Identity used instead | None |

### 6.2 What Is Excluded from Git

The `.gitignore` file excludes:

```
*.tfvars           # Contains environment-specific values including admin password
*.tfstate          # State files may contain resource IDs and outputs
*.tfstate.backup
.terraform/        # Provider binaries
crash.log
```

### 6.3 Planned Improvement — Key Vault Integration

The VM admin password is currently stored in `.tfvars` files managed by the operator. The next phase of this project will store the admin password in **Azure Key Vault** and retrieve it via a Terraform `data` source at apply time. This removes the password from all file-based storage.

> **Security team note:** This is a known gap and is tracked as a planned improvement. The current `.tfvars` approach is mitigated by the Git exclusion rule and the files being managed locally by the deploying engineer only.

---

## 7. Compliance & Governance

### 7.1 Azure Policy Enforcement

Two subscription-level Azure Policy assignments are created by Terraform to enforce tagging on all resource groups:

| Policy | Required Tag | Effect |
|---|---|---|
| `req-tag-managed_by-rg` | `managed_by` | Deny — resource groups without this tag cannot be created |
| `req-tag-created_by-rg` | `created_by` | Deny — resource groups without this tag cannot be created |

Additional tags applied to **every resource** by Terraform:

| Tag | Value Source |
|---|---|
| `project` | `var.project` (from tfvars) |
| `department` | `var.department` (from tfvars) |
| `created_by` | `var.created_by` (from tfvars) |
| `environment` | Derived from `var.environment` |
| `managed_by` | Hardcoded to `"terraform"` |

### 7.2 Management Lock

A `CanNotDelete` Management Lock is applied to the resource group in all environments (Dev, UAT, Production). This prevents accidental deletion of the resource group and all its contents via the Azure Portal or CLI by any user — including subscription owners.

To remove the lock (required before `terraform destroy`), a user needs explicit `Microsoft.Authorization/locks/delete` permission, which is separate from standard Contributor role.

### 7.3 Audit Trail

| Audit Mechanism | What It Captures |
|---|---|
| Git history | Every infrastructure change with author, timestamp, commit message |
| Azure Activity Log | All ARM operations (who did what, when) |
| Log Analytics Workspace | Resource-level logs and metrics for all provisioned services |
| Terraform plan output | Pre-apply review of exactly what will change |

---

## 8. Monitoring & Alerting

### 8.1 Diagnostic Settings

Every provisioned resource forwards logs and metrics to a central **Log Analytics Workspace**. This is enforced in Terraform — not optional per-resource:

| Resource | Log Categories |
|---|---|
| Logic App Standard | `WorkflowRuntime`, `FunctionAppLogs` |
| Storage (Blob) | `StorageRead`, `StorageWrite`, `StorageDelete` |
| Storage (File) | `StorageRead`, `StorageWrite`, `StorageDelete` |
| Windows VM | `AllMetrics` |
| Azure Managed Redis | `AllMetrics` |

### 8.2 Application Insights

An Application Insights instance is provisioned and connected to the Logic App. This provides:

- End-to-end request tracing
- Performance metrics (response times, failure rates)
- Custom alerting based on thresholds
- Live metrics streaming

---

## 9. Engineering Procedures

### 9.1 Terraform Workflow

All infrastructure changes follow this workflow without exception:

```
1. WRITE   — Engineer modifies .tf files or .tfvars locally
2. PLAN    — terraform plan -var-file="environment/{env}.tfvars"
             Output is reviewed line-by-line before proceeding
3. REVIEW  — Second engineer reviews the plan output for Production changes
4. APPLY   — terraform apply -var-file="environment/{env}.tfvars"
5. VALIDATE — Post-apply checks (connectivity, logs flowing, policies active)
6. COMMIT  — Code change committed to Git with descriptive message
```

> **Rule:** No `terraform apply` without a `terraform plan` review. No Production apply without peer review of the plan output.

### 9.2 State Management

| Aspect | Approach |
|---|---|
| State backend | Azure Blob Storage (remote state) |
| State isolation | Separate state file per environment |
| State locking | Azure Blob lease-based locking (prevents concurrent applies) |
| State versioning | Azure Blob versioning enabled |
| State backup | Soft-delete on Blob Storage (minimum 7-day retention) |

> State files are **never committed to Git**. They are `.gitignore`d.

### 9.3 Module Structure

The codebase follows a modular structure where each module is self-contained:

```
modules/
├── network/           — VNet, subnets, NSG
├── storage/           — Storage Account
├── dns_zone/          — Private DNS Zones
├── private_endpoints/ — Private Endpoints for all PaaS services
├── logic_app/         — Logic App Standard + App Service Plan
├── vm/                — Windows Virtual Machine
├── identity/          — User-Assigned Managed Identity + RBAC
├── redis_cache/       — Azure Managed Redis (azapi provider)
├── monitoring/        — Log Analytics + Application Insights
├── governance/        — Azure Policy + Management Lock
└── diagnostic_setting/— Reusable diagnostic settings (1 per resource)
```

Each module exposes only what the root module needs via `outputs.tf`. No module directly references another module's internals.

### 9.4 Change Control Rules

| Rule | Detail |
|---|---|
| All changes via code | No manual changes in Azure Portal to Terraform-managed resources |
| Environment promotion | Changes always flow Dev → UAT → Production; no direct Production changes |
| Breaking changes | Any change that destroys and recreates a resource requires CAB approval |
| Provider upgrades | Tested in Dev for minimum 1 sprint before UAT promotion |
| State manipulation | `terraform state` commands require two-person authorization |

### 9.5 Naming Convention Reference

| Resource Type | Pattern | Example |
|---|---|---|
| Resource Group | `rg-{sub}-{loc}-{app}-{env}` | `rg-corit-eus-app-dev` |
| VNet | `vnet-{sub}-{loc}-{app}-{env}` | `vnet-corit-eus-app-dev` |
| Logic App | `la-{sub}-{loc}-{app}-{env}-{instance}` | `la-corit-eus-app-dev-01` |
| VM | `vm{loc}-{app}{env}-{instance}` | `vmeus-appdev-01` |
| Storage Account | `st{sub}{loc}{app}{env}{instance}` | `stcoriteuseappdev01` |
| Managed Identity | `id-{sub}-{loc}-{app}-{env}` | `id-corit-eus-app-dev` |
| Redis | `redis-{sub}-{loc}-{app}-{env}-{instance}` | `redis-corit-eus-app-dev-01` |
| Log Analytics | `law-{sub}-{loc}-{app}-{env}` | `law-corit-eus-app-dev` |
| App Insights | `appi-{sub}-{loc}-{app}-{env}` | `appi-corit-eus-app-dev` |

### 9.6 Provider Version Policy

| Provider | Pinned Version | Reason |
|---|---|---|
| `hashicorp/azurerm` | `~> 4.0` | Minor-version updates auto-allowed; major upgrade requires explicit test cycle |
| `azure/azapi` | `~> 2.0` | Required for Azure Managed Redis (not yet in azurerm provider) |

---

## 10. Known Gaps & Remediation Plan

| Gap | Risk | Planned Remediation | Timeline |
|---|---|---|---|
| VM admin password in `.tfvars` | Medium | Migrate to Azure Key Vault; Terraform retrieves via `data.azurerm_key_vault_secret` | Next sprint |
| No automated `terraform plan` in CI/CD | Medium | Add GitHub Actions / Azure DevOps pipeline with PR-gated plan output | Next phase |
| Redis API version is `preview` | Low | Migrate to GA API version when Azure Managed Redis GA is released | When available |
| No alerting rules defined | Low | Add `azurerm_monitor_metric_alert` resources for Redis memory, VM CPU, Logic App failures | Next sprint |

---

## 11. Security Team Sign-Off

| Reviewer | Role | Finding | Approved | Date |
|---|---|---|---|---|
| | Security Architect | | ☐ Pending | |
| | Cloud Security Engineer | | ☐ Pending | |
| | Compliance Officer | | ☐ Pending | |

**Conditions of Approval (if any):**

> _(Security team to complete)_

---

## 12. Appendix — Tool Versions

| Tool | Version Required |
|---|---|
| Terraform CLI | >= 1.3.0 |
| Azure CLI | Latest stable |
| azurerm provider | ~> 4.0 |
| azapi provider | ~> 2.0 |
| Azure Subscription Role | Contributor + Policy Contributor |
