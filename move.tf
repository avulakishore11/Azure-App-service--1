moved {
  from = azurerm_private_dns_zone_virtual_network_link.blob_hub
  to   = azurerm_private_dns_zone_virtual_network_link.blob
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.table_hub
  to   = azurerm_private_dns_zone_virtual_network_link.table
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.queue_hub
  to   = azurerm_private_dns_zone_virtual_network_link.queue
}

moved {
  from = azurerm_private_dns_zone_virtual_network_link.file_hub
  to   = azurerm_private_dns_zone_virtual_network_link.file
}
