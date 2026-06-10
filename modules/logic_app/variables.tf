variable "location" {
  description = "Azure location for the Logic App resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the Logic App resources."
  type        = string
}

variable "logic_app_name" {
  description = "Name of the Logic App Standard instance."
  type        = string
}

variable "service_plan_name" {
  description = "App Service plan name for the Logic App."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Logic App VNet integration."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name used by the Logic App Standard runtime."
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key for the storage account used by the Logic App Standard runtime."
  type        = string
  sensitive   = true
}

variable "app_insights_connection_string" {
  description = "Application Insights connection string for telemetry."
  type        = string
  sensitive   = true
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key."
  type        = string
  sensitive   = true
}

variable "health_check_path" {
  description = "HTTP path the platform polls to assess Logic App health."
  type        = string
  default     = "/api/health"
}

variable "tags" {
  description = "Tags to apply to all Logic App resources."
  type        = map(string)
  default     = {}
}
