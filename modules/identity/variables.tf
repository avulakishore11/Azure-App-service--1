variable "location" {
  description = "Azure region for identity resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy identity resources into."
  type        = string
}

variable "identity_name" {
  description = "Name of the user-assigned managed identity."
  type        = string
}

variable "virtual_machine_id" {
  description = "Resource ID of the VM to assign Virtual Machine Contributor to."
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the storage account to scope Logic App storage role assignments."
  type        = string
}

variable "logic_app_principal_id" {
  description = "Principal ID of the Logic App Standard system-assigned managed identity."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all identity resources."
  type        = map(string)
  default     = {}
}
