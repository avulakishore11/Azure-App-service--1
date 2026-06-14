variable "location" {
  description = "Azure location for the private endpoints."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the private endpoints."
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account used by the private endpoints."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account used for private endpoint resource names."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoints."
  type        = string
}

variable "blob_dns_zone_id" {
  description = "Resource ID of the blob private DNS zone."
  type        = string
}

variable "table_dns_zone_id" {
  description = "Resource ID of the table private DNS zone."
  type        = string
}

variable "queue_dns_zone_id" {
  description = "Resource ID of the queue private DNS zone."
  type        = string
}

variable "file_dns_zone_id" {
  description = "Resource ID of the file private DNS zone."
  type        = string
}

variable "deploy_redis_cache" {
  description = "When false, the Redis private endpoint is skipped."
  type        = bool
  default     = true
}

variable "redis_name" {
  description = "Redis instance name — used to name the private endpoint resource."
  type        = string
}

variable "redis_resource_id" {
  description = "Resource ID of the Azure Managed Redis instance."
  type        = string
}

variable "redis_dns_zone_id" {
  description = "Resource ID of the Redis private DNS zone (privatelink.<region>.redis.azure.net)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all private endpoint resources."
  type        = map(string)
  default     = {}
}
