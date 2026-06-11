variable "location" {
  description = "Azure region for the Redis instance."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group — used for azurerm child resources (DNS zone link, etc.)."
  type        = string
}

variable "resource_group_id" {
  description = "Full resource ID of the resource group — required as parent_id for the azapi_resource."
  type        = string
}

variable "redis_name" {
  description = "Name of the Azure Managed Redis instance."
  type        = string
}

variable "redis_sku_size" {
  description = "Balanced tier size. Use Balanced_B0 for dev/uat; resize for prod based on observed Used Memory % and Connected Clients in LAW."
  type        = string
  default     = "Balanced_B0"

  validation {
    condition     = can(regex("^Balanced_B", var.redis_sku_size))
    error_message = "This module is designed for the Balanced tier (Balanced_B0 ... Balanced_B1000)."
  }
}

variable "uami_principal_id" {
  description = "Principal ID of the UAMI granted data-plane access to Redis via the access policy assignment."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all Redis resources."
  type        = map(string)
  default     = {}
}
