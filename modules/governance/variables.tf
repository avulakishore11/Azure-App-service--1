variable "resource_group_id" {
  description = "Resource ID of the resource group — scope for the management lock."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, uat, prod)."
  type        = string
}

variable "lock_level" {
  description = "Management lock level. Use 'CanNotDelete' for UAT/Prod, '' (empty) to skip locking."
  type        = string
  default     = ""

  validation {
    condition     = contains(["", "CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "lock_level must be '', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "tags" {
  description = "Tags applied to governance resources (e.g. the management lock)."
  type        = map(string)
  default     = {}
}
