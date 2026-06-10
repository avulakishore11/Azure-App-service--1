# =============================================================================
# modules/governance/main.tf
# Kaseya Corporate IT — Cloud Infrastructure Team
#
# Governance controls:
#   - Management lock     : CanNotDelete on UAT/Prod resource group
#   - Tag enforcement     : Deny policy on 4 required Kaseya tags,
#                           applied at subscription scope for resources + RGs
#
# Required RBAC for the deployment principal:
#   Resource Policy Contributor — assign policies (recommended for pipelines)
#   Owner / User Access Admin   — only needed for DeployIfNotExists/Modify effects
# =============================================================================

data "azurerm_subscription" "current" {}

# Resource lock — prevents accidental deletion of the environment resource group.
# Skipped when var.lock_level is "" (Dev).
resource "azurerm_management_lock" "rg_lock" {
  count = var.lock_level != "" ? 1 : 0

  name       = "lock-${var.resource_group_name}"
  scope      = var.resource_group_id
  lock_level = var.lock_level
  notes      = "Terraform-managed — ${var.environment}. Removal requires a PR to infrastructure repo."
}

# ── Tag Enforcement ───────────────────────────────────────────────────────────
# Tag keys MUST match exactly what is set in locals.tf (PascalCase).
# Azure tags are case-sensitive — a policy enforcing "project" will NOT match
# a resource tagged "Project", causing all resource creation to be Denied.

locals {
  # Must match the keys in the tags map in locals.tf exactly (all lowercase)
  required_tags = toset(["project", "department", "created_by", "environment", "managed_by"])

  policy_require_tag_on_resources       = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  policy_require_tag_on_resource_groups = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
}

# Enforce required tags on every resource
resource "azurerm_subscription_policy_assignment" "require_tag_resources" {
  for_each = local.required_tags

  name                 = "req-tag-${lower(each.key)}-res"
  display_name         = "Require ${each.key} tag on resources"
  policy_definition_id = local.policy_require_tag_on_resources
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}

# Enforce required tags on every resource group
resource "azurerm_subscription_policy_assignment" "require_tag_resource_groups" {
  for_each = local.required_tags

  name                 = "req-tag-${lower(each.key)}-rg"
  display_name         = "Require ${each.key} tag on resource groups"
  policy_definition_id = local.policy_require_tag_on_resource_groups
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}
