resource "azurerm_service_plan" "logic_app_plan" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = "WS1"
  tags                = var.tags
}

resource "azurerm_logic_app_standard" "logic_app" {
  name                       = var.logic_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_service_plan.logic_app_plan.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  https_only                 = true
  virtual_network_subnet_id  = var.subnet_id
  tags                       = var.tags

  # [Fix 1 — CRITICAL] vnet_content_share_enabled must be true when the storage
  # account has default_action = "Deny" and VNet integration is active. Without
  # this flag the runtime fetches workflow content over the public internet, which
  # the storage firewall blocks → C:\home\site\wwwroot not found at startup.
  vnet_content_share_enabled = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    health_check_path             = var.health_check_path
    ip_restriction_default_action = "Deny"

    ip_restriction {
      virtual_network_subnet_id = var.subnet_id
      action                    = "Allow"
      priority                  = 500
      name                      = "AllowFromVNetSubnet"
    }

    dynamic "ip_restriction" {
      for_each = var.allowed_ip_ranges
      content {
        ip_address = ip_restriction.value
        action     = "Allow"
        priority   = 100 + ip_restriction.key
        name       = "AllowIP-${ip_restriction.key + 1}"
      }
    }
  }

  app_settings = {
    # Route all outbound traffic through the VNet so storage/queue/table traffic
    # flows through private endpoints instead of the public internet.
    "WEBSITE_VNET_ROUTE_ALL" = "1"

    # [Fix 2 — CRITICAL] AzureWebJobsStorage__accountName (managed-identity form)
    # has been intentionally removed. azurerm_logic_app_standard automatically
    # injects AzureWebJobsStorage via the storage_account_name +
    # storage_account_access_key arguments above. Having both the key-based and
    # MI-based forms simultaneously causes the runtime to conflict, producing
    # "secrets\Sentinels access denied" errors. The RBAC roles in the identity
    # module are still present for least-privilege blob/queue/table access; this
    # just removes the duplicate setting that confuses the runtime.

    # [Fix 3 — IMPORTANT] Explicitly pin WEBSITE_CONTENTSHARE to the file share
    # name that Terraform manages in the storage module. Without this the provider
    # auto-generates the value as "<logic-app-name>-content", which doesn't match
    # the pre-created share → the runtime creates a second orphaned share and the
    # Terraform-managed one is never used.
    "WEBSITE_CONTENTSHARE" = var.content_share_name

    # [Fix 5 — MINOR] Explicitly declare the Functions host major version.
    # The provider sets this automatically but omitting it causes Terraform to show
    # a perpetual diff when the Azure portal stamps a different default on the resource.
    "FUNCTIONS_EXTENSION_VERSION" = "~4"

    "FUNCTIONS_WORKER_RUNTIME"                   = "dotnet"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = var.app_insights_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = var.app_insights_instrumentation_key
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }
}
