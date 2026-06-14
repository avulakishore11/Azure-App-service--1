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

    # [Fix 3 — REVISED] WEBSITE_CONTENTSHARE is intentionally omitted from app_settings.
    # azurerm_logic_app_standard injects this setting automatically (derived from the
    # logic app name). Explicitly setting it here sends the value twice in the same
    # CreateOrUpdate call → Azure returns 409 "Parameter already exists". The share
    # in the storage module is renamed to the logic app name so it matches what the
    # provider auto-generates (see modules/storage/main.tf).

    # [Fix 5 — REMOVED] FUNCTIONS_EXTENSION_VERSION is intentionally omitted.
    # azurerm_logic_app_standard manages this setting internally; explicitly setting
    # it in app_settings causes a 409 Conflict ("parameter already exists") from the
    # Azure API because the provider already injected it before processing app_settings.

    "FUNCTIONS_WORKER_RUNTIME"                   = "dotnet"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = var.app_insights_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = var.app_insights_instrumentation_key
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }
}
