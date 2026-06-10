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
    health_check_path = var.health_check_path

    ip_restriction {
      virtual_network_subnet_id = var.subnet_id
      action                    = "Allow"
      priority                  = 500
      name                      = "AllowFromVNetSubnet"
    }
  }

  app_settings = {
    "WEBSITE_VNET_ROUTE_ALL"                  = "1"
    "FUNCTIONS_WORKER_RUNTIME"                = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"            = "~18"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"   = var.app_insights_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"          = var.app_insights_instrumentation_key
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }
}

