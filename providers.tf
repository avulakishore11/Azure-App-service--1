terraform {
  required_version = ">= 1.3.0"

  # azapi is required because Azure Managed Redis (Balanced tier) is not yet
  # supported by the azurerm provider — only azapi_resource covers it.
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.2"
    }
  }
}

provider "azapi" {}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
