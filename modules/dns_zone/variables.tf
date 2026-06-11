variable "resource_group_name" {
  description = "Resource group where the private DNS zones are created."
  type        = string
}

variable "location" {
  description = "Azure region — used to construct the Redis private DNS zone name (privatelink.<region>.redis.azure.net)."
  type        = string
}

variable "vnet_id" {
  description = "ID of the VNet to link to all private DNS zones."
  type        = string
}

variable "tags" {
  description = "Tags to apply to DNS zone resources."
  type        = map(string)
  default     = {}
}
