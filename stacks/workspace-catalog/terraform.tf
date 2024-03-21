terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.96.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~>1.38.0"
    }
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

provider "databricks" {
  host                        = var.databricks_workspace.workspace_url
  azure_workspace_resource_id = var.databricks_workspace.id
  azure_use_msi               = true
}


