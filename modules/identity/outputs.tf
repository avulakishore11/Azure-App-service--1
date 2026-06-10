output "identity_id" {
  value       = azurerm_user_assigned_identity.uami.id
  description = "Resource ID of the user-assigned managed identity."
}

output "identity_principal_id" {
  value       = azurerm_user_assigned_identity.uami.principal_id
  description = "Principal ID of the UAMI (use this for RBAC assignments)."
}

output "identity_client_id" {
  value       = azurerm_user_assigned_identity.uami.client_id
  description = "Client ID of the UAMI (use this in SDK/app configuration)."
}
