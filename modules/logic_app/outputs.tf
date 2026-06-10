output "identity_principal_id" {
  value = azurerm_logic_app_standard.logic_app.identity[0].principal_id
}

output "logic_app_id" {
  value = azurerm_logic_app_standard.logic_app.id
}
