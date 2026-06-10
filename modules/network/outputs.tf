output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "logic_app_subnet_id" {
  value = azurerm_subnet.logic_app.id
}

output "logic_app_subnet_name" {
  value = azurerm_subnet.logic_app.name
}

output "vm_subnet_id" {
  value = azurerm_subnet.vm.id
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoint.id
}

output "vm_nsg_id" {
  value = azurerm_network_security_group.vm_nsg.id
}
