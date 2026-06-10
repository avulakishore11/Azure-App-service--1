output "lock_id" {
  value       = var.lock_level != "" ? azurerm_management_lock.rg_lock[0].id : null
  description = "ID of the management lock, or null when no lock is applied (Dev)."
}
