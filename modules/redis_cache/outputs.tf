output "redis_id" {
  value       = azapi_resource.redis.id
  description = "Resource ID of the Azure Managed Redis instance."
}

output "redis_hostname" {
  value       = azapi_resource.redis.output.properties.hostName
  description = "Hostname for client connections (port 10000, TLS required)."
  sensitive   = true
}
