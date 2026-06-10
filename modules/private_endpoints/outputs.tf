output "blob_private_endpoint_id" {
  value = azurerm_private_endpoint.blob.id
}

output "table_private_endpoint_id" {
  value = azurerm_private_endpoint.table.id
}

output "queue_private_endpoint_id" {
  value = azurerm_private_endpoint.queue.id
}

output "file_private_endpoint_id" {
  value = azurerm_private_endpoint.file.id
}
