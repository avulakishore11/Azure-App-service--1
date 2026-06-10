# =============================================================================
# modules/network/main.tf
# Kaseya Corporate IT — Cloud Infrastructure Team
#
# Creates the spoke VNet, three subnets, three NSGs, and their associations.
#
# CHANGE LOG
# ----------
# [Change 1] tags = var.tags added to azurerm_virtual_network
#            Reason: Kaseya policy requires Department/CreatedBy/Environment/
#            UpdateRing/Project tags on ALL resources. Azure Policy enforces this
#            and will block resource creation without them.
#
# [Change 2] service_endpoints = ["Microsoft.Storage"] on logicAppSubnet
#            Reason: Logic App Standard uses the storage account's access key to
#            create its internal file share at provisioning time. Azure's App
#            Service management plane calls the storage account from outside the
#            VNet, but the storage network rules have default_action = "Deny".
#            Adding the Microsoft.Storage service endpoint to this subnet and
#            whitelisting the subnet in the storage network_rules lets the Logic
#            App runtime reach storage via the service endpoint path instead of
#            the public internet — resolving the 403 Forbidden during file share
#            creation.
#
# [Change 3] delegation block on logicAppSubnet → Microsoft.Web/serverFarms
#            Reason: Logic App Standard with VNet Integration requires the subnet
#            to be delegated to Microsoft.Web/serverFarms. Without this delegation
#            Azure returns HTTP 400: "Subnet is missing a delegation to
#            Microsoft.Web/serverFarms."
#
# [Change 4] depends_on = [azurerm_subnet.logic_app] on vmSubnet
#            depends_on = [azurerm_subnet.vm]          on privateEndpointSubnet
#            Reason: The AzureRM provider has a known concurrency bug when
#            multiple azurerm_subnet resources for the same VNet are created in
#            parallel — it can produce "Root object was present, but now absent."
#            Sequential creation (logic_app → vm → private_endpoint) avoids it.
#
# [Change 5] private_endpoint_network_policies = "Disabled" on privateEndpointSubnet
#            Reason: The old boolean argument private_endpoint_network_policies_enabled
#            was removed in AzureRM provider v4.x. The replacement is a string
#            argument: "Disabled" (equivalent to the old = false).
#
# [Change 6] azurerm_subnet_network_security_group_association resources added
#            Reason: The old approach attached NSGs via the deprecated
#            network_security_group_id argument on azurerm_network_interface and
#            directly on subnet blocks. The current provider requires a separate
#            association resource for subnet-to-NSG attachment.
#
# [Change 7] NSG priority numbering aligned to Kaseya standard:
#              500–510 : Application-specific allow rules (evaluated first)
#              1100    : Corporate default DenyAllInbound (evaluated last)
#            DenyAllOutbound rules were removed — outbound traffic is managed
#            by the Palo Alto Firewall as the VNet next hop per Kaseya policy.
# =============================================================================

# -----------------------------------------------------------------------------
# Virtual Network
# [Change 1] tags added — required by Kaseya tagging policy and Azure Policy
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_prefix]
  tags                = var.tags
}

# =============================================================================
# Subnets
# NSGs are required on subnets with PaaS VNet Integration (Logic App Standard)
# and on private endpoint subnets per Microsoft recommendation.
# =============================================================================

# -----------------------------------------------------------------------------
# Logic App Subnet
# [Change 2] service_endpoints = ["Microsoft.Storage"] — allows Logic App to
#            reach the storage account via service endpoint (avoids 403 on file
#            share creation). Must be paired with storage network_rules allowlist.
# [Change 3] delegation to Microsoft.Web/serverFarms — required for Logic App
#            Standard VNet Integration (Azure returns 400 without this).
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "logic_app" {
  name                 = "logicAppSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.logic_app_subnet_prefix]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "logic-app-subnet-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# -----------------------------------------------------------------------------
# VM Subnet
# [Change 4] depends_on = [azurerm_subnet.logic_app] — forces sequential subnet
#            creation to avoid the AzureRM provider parallel-subnet bug that
#            causes "Root object was present, but now absent."
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "vm" {
  name                 = "vmSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.vm_subnet_prefix]

  depends_on = [azurerm_subnet.logic_app]
}

# -----------------------------------------------------------------------------
# Private Endpoint Subnet
# [Change 4] depends_on = [azurerm_subnet.vm] — continues the sequential chain.
# [Change 5] private_endpoint_network_policies = "Disabled" — replaces the
#            removed boolean private_endpoint_network_policies_enabled = false.
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "private_endpoint" {
  name                 = "privateEndpointSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.private_endpoint_subnet_prefix]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false #Private Endpoint needs its own subnet You can't reuse the workload subnet — PE subnet should have private_endpoint_network_policies = Disabled

  depends_on = [azurerm_subnet.vm]
}

# =============================================================================
# NSG → Subnet Associations
# [Change 6] Separate association resources replace the deprecated inline
#            network_security_group_id argument on subnet blocks.
# =============================================================================
resource "azurerm_subnet_network_security_group_association" "logic_app" {
  subnet_id                 = azurerm_subnet.logic_app.id
  network_security_group_id = azurerm_network_security_group.logic_app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoint" {
  subnet_id                 = azurerm_subnet.private_endpoint.id
  network_security_group_id = azurerm_network_security_group.private_endpoint_nsg.id
}

# =============================================================================
# Network Security Groups
#
# [Change 7] Priority numbering aligned to Kaseya NSG standard:
#   500–599  Application-specific allow rules (evaluated before corporate rules)
#   1000–1100 Corporate defaults (DenyAllInbound at 1100)
#   Outbound DenyAll removed — Palo Alto FW manages outbound as VNet next hop.
#
# Rule rationale per NSG:
#   logic_app_nsg   : Allow outbound to VM (workflow triggers) and to private
#                     endpoint subnet (storage access). Deny all other inbound.
#   vm_nsg          : Allow inbound from Logic App (triggered by workflows).
#                     Allow outbound back to Logic App (response traffic).
#                     Deny all other inbound.
#   private_endpoint_nsg : Allow inbound from Logic App (storage reads/writes).
#                          Allow outbound back to Logic App (response traffic).
#                          Deny all other inbound.
# =============================================================================

resource "azurerm_network_security_group" "logic_app_nsg" {
  name                = "${var.vnet_name}-nsg-logicapp"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # [Change 7] Priority 500 — application rule (was 100 before alignment)
  security_rule {
    name                       = "AllowOutboundToVm"
    priority                   = 500
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.logic_app_subnet_prefix
    destination_address_prefix = var.vm_subnet_prefix
  }

  # [Change 7] Priority 510 — application rule (was 110 before alignment)
  security_rule {
    name                       = "AllowOutboundToPrivateEndpoint"
    priority                   = 510
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.logic_app_subnet_prefix
    destination_address_prefix = var.private_endpoint_subnet_prefix
  }

  # [Change 7] Priority 1100 — Kaseya corporate default (was 4096 before alignment)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vnet_name}-nsg-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # [Change 7] Priority 500 — application rule
  security_rule {
    name                       = "AllowInboundFromLogicApp"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.logic_app_subnet_prefix
    destination_address_prefix = var.vm_subnet_prefix
  }

  # [Change 7] Priority 510 — application rule
  security_rule {
    name                       = "AllowOutboundToLogicApp"
    priority                   = 510
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vm_subnet_prefix
    destination_address_prefix = var.logic_app_subnet_prefix
  }

  # [Change 7] Priority 1100 — Kaseya corporate default
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "private_endpoint_nsg" {
  name                = "${var.vnet_name}-nsg-privateendpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # [Change 7] Priority 500 — application rule
  security_rule {
    name                       = "AllowInboundFromLogicApp"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.logic_app_subnet_prefix
    destination_address_prefix = var.private_endpoint_subnet_prefix
  }

  # [Change 7] Priority 510 — application rule
  security_rule {
    name                       = "AllowOutboundFromLogicApp"
    priority                   = 510
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.private_endpoint_subnet_prefix
    destination_address_prefix = var.logic_app_subnet_prefix
  }

  # [Change 7] Priority 1100 — Kaseya corporate default
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
