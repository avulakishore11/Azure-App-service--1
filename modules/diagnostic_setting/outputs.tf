output "diagnostic_setting_id" {
  value       = azurerm_monitor_diagnostic_setting.diagnostic_setting.id
  description = "Resource ID of the diagnostic setting."
}
