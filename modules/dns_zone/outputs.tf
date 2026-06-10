output "blob_dns_zone_id" {
  value       = azurerm_private_dns_zone.blob.id
  description = "Resource ID of the blob private DNS zone."
}

output "table_dns_zone_id" {
  value       = azurerm_private_dns_zone.table.id
  description = "Resource ID of the table private DNS zone."
}

output "queue_dns_zone_id" {
  value       = azurerm_private_dns_zone.queue.id
  description = "Resource ID of the queue private DNS zone."
}

output "file_dns_zone_id" {
  value       = azurerm_private_dns_zone.file.id
  description = "Resource ID of the file private DNS zone."
}
