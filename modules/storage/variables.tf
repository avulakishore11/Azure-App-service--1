variable "location" {
  description = "Azure location for the storage resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the storage resources."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account."
  type        = string
}

variable "sku_name" {
  description = "Storage account SKU."
  type        = string
}

variable "logic_app_subnet_id" {
  description = "Resource ID of the Logic App subnet. Added to the storage network allow-list so the Logic App runtime can reach the file share via service endpoint."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all storage resources."
  type        = map(string)
  default     = {}
}
