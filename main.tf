# =============================================================================
# Deployment order (Terraform resolves via implicit refs + explicit depends_on):
#
#   1. azurerm_resource_group.resource_group
#   2. module.network          (needs RG)
#   3. module.storage          (needs RG + network)
#   4. module.dns_zone         (needs RG, VNet)
#   5. module.vm               (needs RG, network)
#   6. module.identity         (needs RG, VM id)
#   7. module.redis_cache      (needs RG id + UAMI principal_id)
#   8. module.private_endpoints (needs RG, network, storage, dns_zone, redis_cache)
#   9. module.logic_app        (needs RG, network, storage)
#  10. module.governance       (needs RG id)
#  11. azurerm_role_assignment (needs VM id + Logic App identity)
# =============================================================================

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  location                       = var.location
  resource_group_name            = azurerm_resource_group.resource_group.name
  vnet_name                      = local.vnet_name
  address_prefix                 = var.vnet_address_prefix
  logic_app_subnet_prefix        = var.logic_app_subnet_prefix
  vm_subnet_prefix               = var.vm_subnet_prefix
  private_endpoint_subnet_prefix = var.private_endpoint_subnet_prefix
  tags                           = local.tags
}

module "storage" {
  source = "./modules/storage"

  location             = var.location
  resource_group_name  = azurerm_resource_group.resource_group.name
  storage_account_name = local.storage_account_name
  sku_name             = var.storage_sku
  tags                 = local.tags
}

module "private_endpoints" {
  source = "./modules/private_endpoints"

  location                   = var.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  storage_account_id         = module.storage.storage_account_id
  storage_account_name       = local.storage_account_name
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id
  blob_dns_zone_id           = module.dns_zone.blob_dns_zone_id
  table_dns_zone_id          = module.dns_zone.table_dns_zone_id
  queue_dns_zone_id          = module.dns_zone.queue_dns_zone_id
  file_dns_zone_id           = module.dns_zone.file_dns_zone_id
  redis_name                 = local.redis_name
  redis_resource_id          = module.redis_cache.redis_id
  redis_dns_zone_id          = module.dns_zone.redis_dns_zone_id
  tags                       = local.tags

  depends_on = [module.network, module.storage, module.dns_zone, module.redis_cache]
}

module "dns_zone" {
  source = "./modules/dns_zone"

  resource_group_name = azurerm_resource_group.resource_group.name
  vnet_id             = module.network.vnet_id
  location            = var.location
  tags                = local.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  workspace_name      = local.workspace_name
  app_insights_name   = local.app_insights_name
  log_retention_days  = var.log_retention_days
  tags                = local.tags
}


module "logic_app" {
  source = "./modules/logic_app"

  location                         = var.location
  resource_group_name              = azurerm_resource_group.resource_group.name
  logic_app_name                   = local.logic_app_name
  service_plan_name                = local.logic_app_plan_name
  subnet_id                        = module.network.logic_app_subnet_id
  storage_account_name             = module.storage.storage_account_name
  storage_account_access_key       = module.storage.storage_account_primary_access_key
  storage_account_id               = module.storage.storage_account_id
  app_insights_connection_string   = module.monitoring.app_insights_connection_string
  app_insights_instrumentation_key = module.monitoring.app_insights_instrumentation_key
  health_check_path                = var.health_check_path
  tags                             = local.tags
}

module "vm" {
  source = "./modules/vm"

  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  vm_name             = local.vm_name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  subnet_id           = module.network.vm_subnet_id
  nsg_id              = module.network.vm_nsg_id
  tags                = local.tags
}

module "identity" {
  source = "./modules/identity"

  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  identity_name       = local.identity_name
  virtual_machine_id  = module.vm.vm_id
  tags                = local.tags
}

module "governance" {
  count  = var.deploy_governance ? 1 : 0 # Governance module is optional based on the deploy_governance variable
  source = "./modules/governance"

  resource_group_id   = azurerm_resource_group.resource_group.id
  resource_group_name = azurerm_resource_group.resource_group.name
  environment         = var.environment
  lock_level          = var.lock_level
  tags                = local.tags
}

module "redis_cache" {
  source = "./modules/redis_cache"

  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  resource_group_id   = azurerm_resource_group.resource_group.id
  redis_name          = local.redis_name
  redis_sku_size      = var.redis_sku_size
  uami_principal_id   = module.identity.identity_principal_id
  tags                = local.tags
}

resource "azurerm_role_assignment" "logic_app_vm_contributor" {
  scope                = module.vm.vm_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = module.logic_app.identity_principal_id
}

# =============================================================================
# Diagnostic settings — one per resource, all routing to the same LAW.
# Placed here (not inside modules) so each module stays self-contained and
# there is no circular dependency between monitoring ↔ logic_app.
# =============================================================================

# Logic App — valid categories for Microsoft.Web/sites (Logic App Standard)
module "diag_logic_app" {
  source                     = "./modules/diagnostic_setting"
  name                       = "diag-${local.logic_app_name}"
  target_resource_id         = module.logic_app.logic_app_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  log_categories             = ["WorkflowRuntime", "FunctionAppLogs"]
}

# Storage blob service
module "diag_storage_blob" {
  source                     = "./modules/diagnostic_setting"
  name                       = "diag-${local.storage_account_name}-blob"
  target_resource_id         = "${module.storage.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = module.monitoring.workspace_id
  log_categories             = ["StorageRead", "StorageWrite", "StorageDelete"]
}

# Storage file service
module "diag_storage_file" {
  source                     = "./modules/diagnostic_setting"
  name                       = "diag-${local.storage_account_name}-file"
  target_resource_id         = "${module.storage.storage_account_id}/fileServices/default"
  log_analytics_workspace_id = module.monitoring.workspace_id
  log_categories             = ["StorageRead", "StorageWrite", "StorageDelete"]
}

# VM — VMs have no diagnostic log categories, only AllMetrics
module "diag_vm" {
  source                     = "./modules/diagnostic_setting"
  name                       = "diag-${local.vm_name}"
  target_resource_id         = module.vm.vm_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  log_categories             = []
}

# Azure Managed Redis — metrics only (no GA log categories for redisEnterprise)
module "diag_redis" {
  source                     = "./modules/diagnostic_setting"
  name                       = "diag-${local.redis_name}"
  target_resource_id         = module.redis_cache.redis_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  log_categories             = []
}

# Key Vault — uncomment once the identity module Key Vault is re-wired
# module "diag_key_vault" {
#   source                     = "./modules/diagnostic_setting"
#   name                       = "diag-${local.key_vault_name}"
#   target_resource_id         = module.identity.key_vault_id
#   log_analytics_workspace_id = module.monitoring.workspace_id
#   log_categories             = ["AuditEvent"]
# }