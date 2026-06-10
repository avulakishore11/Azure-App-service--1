variable "location" {
  description = "Azure location for the VM resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the VM resources."
  type        = string
}

variable "vm_name" {
  description = "Name of the virtual machine."
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine." 
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM."
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Subnet ID for the VM NIC."
  type        = string
}

variable "nsg_id" {
  description = "Network security group ID attached to the VM NIC."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all VM resources."
  type        = map(string)
  default     = {}
}
