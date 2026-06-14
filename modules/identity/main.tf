# =============================================================================
# modules/identity/main.tf
# Kaseya Corporate IT — Cloud Infrastructure Team
#
# Creates the identity plane for each environment:
#   - User-assigned managed identity (UAMI)
#   - Virtual Machine Contributor role assignment scoped to the environment VM
# =============================================================================

resource "azurerm_user_assigned_identity" "uami" {
  name                = var.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Grant the UAMI Virtual Machine Contributor on the environment VM.
# Scoped to the single VM — not the RG — to follow least-privilege.
resource "azurerm_role_assignment" "uami_vm_contributor" {
  scope                = var.virtual_machine_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}


# -----------------------------------------------------------------------------
# Role assignments — scope each to the storage account, not the subscription,
# to follow least-privilege. System-assigned identity is created with the Logic
# App so principal_id is available once the resource exists.
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "logic_app_storage_blob_owner" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.logic_app_principal_id
}

resource "azurerm_role_assignment" "logic_app_storage_queue_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = var.logic_app_principal_id
}

resource "azurerm_role_assignment" "logic_app_storage_table_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = var.logic_app_principal_id
}