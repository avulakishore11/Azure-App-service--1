locals {
  sku_parts = split("_", var.sku_name)
}

resource "azurerm_storage_account" "storage_account" {
  name                            = var.storage_account_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = local.sku_parts[0]
  account_replication_type        = local.sku_parts[1]
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  # All public network access disabled — file share and Logic App runtime
  # traffic route exclusively through private endpoints within the VNet.
  public_network_access_enabled   = true
  # Shared key access must remain enabled — Logic App Standard uses the
  # account name + key to mount its internal file share at startup.
  shared_access_key_enabled       = true
  tags                            = var.tags

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices", "Logging", "Metrics"]
  }
}

resource "azurerm_storage_share" "fileshare" {
  name               = "fileshare"
  storage_account_id = azurerm_storage_account.storage_account.id
  quota              = 100
}
