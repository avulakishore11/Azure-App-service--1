output "workspace_id" {
  value       = azurerm_log_analytics_workspace.law.id
  description = "Resource ID of the Log Analytics Workspace."
}

output "workspace_name" {
  value       = azurerm_log_analytics_workspace.law.name
  description = "Name of the Log Analytics Workspace."
}

output "app_insights_id" {
  value       = azurerm_application_insights.app_insights.id
  description = "Resource ID of the Application Insights instance."
}

output "app_insights_connection_string" {
  value       = azurerm_application_insights.app_insights.connection_string
  description = "Application Insights connection string — pass to Logic App app_settings."
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  value       = azurerm_application_insights.app_insights.instrumentation_key
  description = "Application Insights instrumentation key."
  sensitive   = true
}
