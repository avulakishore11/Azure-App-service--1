variable "name" {
  description = "Name of the diagnostic setting."
  type        = string
}

variable "target_resource_id" {
  description = "Resource ID of the resource to attach the diagnostic setting to."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace to send logs and metrics to."
  type        = string
}

variable "log_categories" {
  description = "List of log category names to enable. Pass [] for resources that only support metrics (e.g. VMs)."
  type        = list(string)
  default     = []
}

variable "metrics_enabled" {
  description = "Whether to enable AllMetrics collection."
  type        = bool
  default     = true
}
