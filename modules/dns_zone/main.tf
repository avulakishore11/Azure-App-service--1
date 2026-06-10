# =============================================================================
# Private DNS Zones
# -----------------------------------------------------------------------------
# These zones MUST live in the HUB resource group, not the spoke RG where the PEs are created.
# NOT in the spoke RG. If created per-spoke, DNS resolution breaks cross-spoke.
#
# Each zone needs:
#   1. The zone resource itself
#   2. A VNet link to the hub VNet
#   3. A VNet link to EACH spoke VNet that needs to resolve storage names
#      (add more azurerm_private_dns_zone_virtual_network_link blocks per spoke)
# =============================================================================

# -----------------------------------------------------------------------------
# Blob DNS Zone
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

  resource "azurerm_private_dns_zone_virtual_network_link" "blob"{
    name                  = "blob-vnet-link"
    #resource_group_name   = var.hub_resource_group_name
    resource_group_name =  var.resource_group_name
    private_dns_zone_name = azurerm_private_dns_zone.blob.name
    virtual_network_id    = var.vnet_id             # ← HUB VNet link
    registration_enabled  = false    
    tags                  = var.tags
    # never enable auto-registration on PE zones
    
}

# -----------------------------------------------------------------------------
# Table DNS Zone
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  #resource_group_name = var.hub_resource_group_name
  resource_group_name =  var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "table-vnet-link"
  #resource_group_name   = var.hub_resource_group_name
  resource_group_name =  var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}


# -----------------------------------------------------------------------------
# Queue DNS Zone
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  #resource_group_name = var.hub_resource_group_name
  resource_group_name =  var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "queue-vnet-link"
  #resource_group_name   = var.hub_resource_group_name
  resource_group_name =  var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}


# -----------------------------------------------------------------------------
# File DNS Zone
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  #resource_group_name = var.hub_resource_group_name
  resource_group_name =  var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "file-vnet-link"
  #resource_group_name   = var.hub_resource_group_name
  resource_group_name =  var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}