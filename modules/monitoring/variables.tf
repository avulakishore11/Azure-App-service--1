variable "location" {
  description = "Azure region for monitoring resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy monitoring resources into."
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics Workspace."
  type        = string
}

variable "app_insights_name" {
  description = "Name of the Application Insights instance."
  type        = string
}

variable "log_retention_days" {
  description = "Log Analytics data retention in days (30–730)."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "tags" {
  description = "Tags to apply to all monitoring resources."
  type        = map(string)
  default     = {}
}
