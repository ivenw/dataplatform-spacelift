terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.83"
    }
  }
}

variable "application_slug" {
  type = string
}
variable "location" {
  type = string
}
variable "environment" {
  description = "The environment of the resource group. i.e. `dev`, `test`, `prod`."
  type        = string
}
variable "vsts_config" {
  description = "The configuration for the VSTS integration."
  type = object({
    account_name    = string
    project_name    = string
    repository_name = string
    branch_name     = string
    root_folder     = string
  })
  default = null
}
variable "global_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

locals {
  workload   = ["integration"]
  stack_tags = {}
  tags       = merge(var.global_tags, local.stack_tags)
}

module "locations" {
  source   = "azurerm/locations/azure"
  version  = "0.2.4"
  location = var.location
}
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}
module "resource_names" {
  source = "../../modules/resource-name"
  for_each = {
    rg  = module.naming.resource_group,
    adf = module.naming.data_factory,
    st  = module.naming.storage_account
  }
  application_slug = var.application_slug
  naming_data      = each.value
  location_data    = module.locations
  environment      = var.environment
  workload         = local.workload
}

data "azurerm_client_config" "this" {}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = var.location
  tags     = local.tags
}

resource "azurerm_data_factory" "this" {
  name                            = module.resource_names["adf"].name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  managed_virtual_network_enabled = true
  tags                            = local.tags

  global_parameter {
    name  = "environment"
    type  = "String"
    value = var.environment
  }

  identity {
    type = "SystemAssigned"
  }

  # should public_networ_enabled be false?
  dynamic "vsts_configuration" {
    for_each = var.vsts_config != null ? [1] : []

    content {
      # more of this needs be moved into variables and config
      tenant_id       = data.azurerm_client_config.this.tenant_id
      account_name    = var.vsts_config.account_name
      project_name    = var.vsts_config.project_name
      repository_name = var.vsts_config.repository_name
      branch_name     = var.vsts_config.branch_name
      root_folder     = var.vsts_config.root_folder
      # check if we want to have `publishing_enabled` true
    }
  }

  lifecycle {
    ignore_changes = [
      vsts_configuration,
      global_parameter
    ]
  }
}

module "lake_storage_landing" {
  source = "../../modules/lake-storage"

  name           = module.resource_names["st"].name
  resource_group = azurerm_resource_group.this
  tags           = local.tags
}


locals {
  adf_data = {
    name = azurerm_data_factory.this.name
    id   = azurerm_data_factory.this.id
  }
}

output "data_factory" {
  value = local.adf_data
}

