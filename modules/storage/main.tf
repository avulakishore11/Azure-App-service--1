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
  public_network_access_enabled   = true
  # Shared key access must remain enabled — Logic App Standard uses the
  # account name + key to mount its internal file share at startup.
  shared_access_key_enabled = true
  tags                      = var.tags

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    virtual_network_subnet_ids = [var.logic_app_subnet_id]
    ip_rules                   = var.allowed_ip_rules # Added to allow-list so you can access the storage account from your client IP (e.g. Storage Explorer, portal).
  }
}

# [Fix 3 — REVISED] Share name matches what azurerm_logic_app_standard auto-generates
# for WEBSITE_CONTENTSHARE (the logic app name in lowercase). WEBSITE_CONTENTSHARE
# cannot be set in app_settings (provider injects it → 409 Conflict), so the share
# must be pre-created with the name the provider will derive automatically.
resource "azurerm_storage_share" "fileshare" {
  name               = var.content_share_name
  storage_account_id = azurerm_storage_account.storage_account.id
  quota              = 100
}
