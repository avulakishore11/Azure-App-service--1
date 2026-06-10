# =============================================================================
# modules/monitoring/main.tf
# Kaseya Corporate IT — Cloud Infrastructure Team
#
# Creates the observability stack for each environment:
#   - Log Analytics Workspace  : central log sink for all diagnostic settings
#   - Application Insights     : workspace-based, wired to the Logic App
#
# Diagnostic settings per resource are created in the root main.tf via the
# diagnostic_setting module to avoid circular dependencies.
# =============================================================================

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Workspace-based Application Insights (classic mode deprecated by Microsoft).
resource "azurerm_application_insights" "app_insights" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = var.tags
}
