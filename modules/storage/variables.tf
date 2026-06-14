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

variable "content_share_name" {
  description = "Name of the Azure file share created for the Logic App Standard runtime. Must match WEBSITE_CONTENTSHARE in the Logic App app_settings — if they differ the runtime auto-creates a second share and this one is orphaned."
  type        = string
  default     = "fileshare"
}

variable "allowed_ip_rules" {
  description = "List of public IP addresses or CIDR ranges allowed through the storage account firewall (e.g. your client IP for Storage Explorer / portal access)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all storage resources."
  type        = map(string)
  default     = {}
}
