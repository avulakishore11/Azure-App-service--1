# =============================================================================
# modules/private_endpoint/storage_endpoints.tf
# Kaseya Corporate IT — Cloud Infrastructure Team
#
# Creates Private Endpoints for all four Storage subresources:
#   blob, table, queue, file
#
# VM PE block intentionally excluded — VMs are already private (subnet NIC).
# PE is for PaaS services which have public endpoints.
#
# DNS zones live in the HUB resource group — IDs passed in via variables.
# This module never creates DNS zones — it only registers into existing ones.
# =============================================================================

# -----------------------------------------------------------------------------
# Blob Private Endpoint
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "blob" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags
# The connection_method block automatically creates a Private Link

  private_service_connection {
    name                           = "blobConnection"
    private_connection_resource_id = var.storage_account_id # ID of the resource (Resource_type ) we're connecting to (the storage account)
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dzg"
    private_dns_zone_ids = [var.blob_dns_zone_id]
  }
}

# -----------------------------------------------------------------------------
# Table Private Endpoint
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "table" {
  name                = "${var.storage_account_name}-table-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "tableConnection"
    private_connection_resource_id = var.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  private_dns_zone_group {
    name                 = "table-dzg"
    private_dns_zone_ids = [var.table_dns_zone_id]
  }
}

# -----------------------------------------------------------------------------
# Queue Private Endpoint
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "queue" {
  name                = "${var.storage_account_name}-queue-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "queueConnection"
    private_connection_resource_id = var.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }

  private_dns_zone_group {
    name                 = "queue-dzg"
    private_dns_zone_ids = [var.queue_dns_zone_id]
  }
}

# -----------------------------------------------------------------------------
# File Private Endpoint
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "file" {
  name                = "${var.storage_account_name}-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "fileConnection"
    private_connection_resource_id = var.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "file-dzg"
    private_dns_zone_ids = [var.file_dns_zone_id]
  }
}

