output "logic_app_identity_principal_id" {
  value       = module.logic_app.identity_principal_id
  description = "Principal ID of the Logic App system-assigned managed identity."
}

output "storage_account_id" {
  value       = module.storage.storage_account_id
  description = "ID of the deployed storage account."
}

output "vm_id" {
  value       = module.vm.vm_id
  description = "ID of the deployed virtual machine."
}

output "vnet_id" {
  value       = module.network.vnet_id
  description = "ID of the deployed virtual network."
}

output "private_endpoints" {
  value = {
    blob  = module.private_endpoints.blob_private_endpoint_id
    table = module.private_endpoints.table_private_endpoint_id
    queue = module.private_endpoints.queue_private_endpoint_id
    file  = module.private_endpoints.file_private_endpoint_id
  }
  description = "Private endpoint IDs for the storage account."
}


output "user_assigned_identity_id" {
  value       = module.identity.identity_id
  description = "Resource ID of the user-assigned managed identity."
}

output "log_analytics_workspace_id" {
  value       = module.monitoring.workspace_id
  description = "Resource ID of the Log Analytics Workspace."
}

output "app_insights_id" {
  value       = module.monitoring.app_insights_id
  description = "Resource ID of the Application Insights instance."
}

output "app_insights_connection_string" {
  value       = module.monitoring.app_insights_connection_string
  description = "Application Insights connection string."
  sensitive   = true
}
