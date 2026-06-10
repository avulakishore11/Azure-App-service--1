terraform {
  backend "azurerm" {
    resource_group_name  = "tgts-tfstatedev-01"
    storage_account_name = "saterrastatedev02"
    container_name       = "tfstate"
    use_azuread_auth     = true
    # key is injected per-environment by the pipeline (TerraformTaskV4 backendAzureRmKey)
  }
}