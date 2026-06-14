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
    "WEBSITE_VNET_ROUTE_ALL"                     = "1" # Route all outbound traffic through the VNet, including to Azure services. if you want to allow direct access to Azure services, set this to 0 and add service endpoints for the storage account.
    "FUNCTIONS_WORKER_RUNTIME"                   = "dotnet"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = var.app_insights_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = var.app_insights_instrumentation_key
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"

    # Blob, Queue, Table — use system-assigned MI instead of access key.
    # Double-underscore prefix tells the Functions runtime to authenticate
    # via managed identity; the file share still uses the access key above.
    "AzureWebJobsStorage__accountName" = var.storage_account_name
  }
}