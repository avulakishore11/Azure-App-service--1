# =============================================================================
# modules/diagnostic_setting/main.tf
# Kaseya Corporate IT — Cloud Infrastructure Team
#
# Generic diagnostic setting — attach to any Azure resource.
# Pass log_categories = [] for resources that only expose metrics (e.g. VMs).
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
  name                       = var.name
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(var.log_categories)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
