variable "location" {
  description = "Azure location for the network resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the network resources."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "address_prefix" {
  description = "Address prefix for the VNet."
  type        = string
}

variable "logic_app_subnet_prefix" {
  description = "Address prefix for the Logic App subnet."
  type        = string
}

variable "vm_subnet_prefix" {
  description = "Address prefix for the VM subnet."
  type        = string
}

variable "private_endpoint_subnet_prefix" {
  description = "Address prefix for the private endpoint subnet."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all network resources."
  type        = map(string)
  default     = {}
}
