locals {
  location_code = var.location_code_override != "" ? var.location_code_override : lookup({
    eastus        = "eus"
    eastus2       = "eus2"
    westus        = "wus"
    westus2       = "wus2"
    centralus     = "cus"
    northeurope   = "neu"
    westeurope    = "weu"
    southeastasia = "sea"
    australiaeast = "aue"
    japaneast     = "jpe"
    koreasouth    = "krs"
  }, lower(var.location), replace(lower(var.location), "/[^a-z0-9]/", ""))

  sub              = lower(var.subscription)
  app              = lower(var.app_name)
  env              = lower(var.environment)
  env_segment      = local.env != "" ? "-${local.env}" : ""
  instance_segment = var.instance != "" ? "-${var.instance}" : ""

  common_prefix = "${local.sub}-${local.location_code}"

  resource_group_name = "rg-${local.common_prefix}-${local.app}${local.env_segment}"
  vnet_name           = "vnet-${local.common_prefix}-${local.app}${local.env_segment}"

  # Storage account names: lowercase alphanumeric only, max 24 chars
  storage_account_name = lower(substr(
    replace(
      "st${local.sub}${local.location_code}${local.app}${local.env}${var.instance != "" ? var.instance : ""}",
      "-",
      ""
    ),
    0,
    24
  ))

  logic_app_name      = "la-${local.common_prefix}-${local.app}${local.env_segment}${local.instance_segment}"
  logic_app_plan_name = "asp-${local.common_prefix}-${local.app}${local.env_segment}"

  # VM names: max 15 chars to match NETBIOS limit
  vm_name = substr(lower("vm${local.location_code}-${local.app}${local.env}${local.instance_segment}"), 0, 15)

  identity_name      = "id-${local.common_prefix}-${local.app}${local.env_segment}"
  workspace_name     = "law-${local.common_prefix}-${local.app}${local.env_segment}"
  app_insights_name  = "appi-${local.common_prefix}-${local.app}${local.env_segment}"

  # Required Kaseya tags applied to every resource
  tags = {
    Project     = var.project
    Department  = var.department
    CreatedBy   = var.created_by
    Environment = local.env
  }
}
