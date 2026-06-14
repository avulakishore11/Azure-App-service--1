variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
  default     = "7a6d2623-b7d9-467b-ab2f-d71d7bf6d45d"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "location_code_override" {
  description = "Optional short code used in resource names instead of the auto-derived one (e.g. 'eus')."
  type        = string
  default     = ""
}

variable "subscription" {
  description = "Subscription short name used in resource naming."
  type        = string
}

variable "app_name" {
  description = "Application or service name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, uat, prod) — used in resource naming and tags."
  type        = string
}

variable "instance" {
  description = "Optional instance suffix used in resource naming."
  type        = string
}

variable "storage_sku" {
  description = "Storage account SKU (e.g. Standard_LRS, Standard_ZRS)."
  type        = string
}

variable "vm_size" {
  description = "Virtual machine SKU."
  type        = string
}

variable "admin_username" {
  description = "Administrator username for the Windows VM."
  type        = string
}

variable "admin_password" {
  description = "Administrator password for the Windows VM."
  type        = string
  sensitive   = true
}

variable "vnet_address_prefix" {
  description = "Address prefix for the virtual network."
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

variable "lock_level" {
  description = "Management lock level applied to the resource group. Use 'CanNotDelete' for UAT/Prod, '' to skip."
  type        = string
  default     = ""

  validation {
    condition     = contains(["", "CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "lock_level must be '', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "project" {
  description = "Project name tag — required by Azure Policy on all resource groups."
  type        = string
}

variable "department" {
  description = "Kaseya department tag (e.g. 'Corporate IT', 'BIS')."
  type        = string
}

variable "created_by" {
  description = "Email or name of the person provisioning these resources."
  type        = string
}

variable "log_retention_days" {
  description = "Log Analytics Workspace data retention in days."
  type        = number
  default     = 30
}

variable "health_check_path" {
  description = "HTTP path polled by the platform to assess Logic App health."
  type        = string
  default     = "/api/health"
}

variable "logic_app_allowed_ip_ranges" {
  description = "IP address ranges (CIDR notation) allowed to access the Logic App in addition to its VNet subnet (e.g. on-prem ranges or trusted public IPs)."
  type        = list(string)
  default     = []
}

variable "redis_sku_size" {
  description = "Azure Managed Redis Balanced tier size. Use Balanced_B0 for dev/uat; increase for prod based on observed memory and client metrics."
  type        = string
  default     = "Balanced_B0"
}

# Optional toggles for modules that aren't always needed (e.g. governance in dev, Redis Cache if not using it at all, etc.)

variable "deploy_redis_cache" {
  description = "Set to false to skip provisioning the Redis Cache module. Useful if you don't need Redis or are deploying to an environment where it already exists."
  type        = bool
  default     = true
}

variable "deploy_governance" {
  description = "Set to false to skip the governance module (policy assignments + management lock). Useful when policies already exist at the subscription level."
  type        = bool
  default     = true
}