locals {
  # constants 
  workload_uc        = ["uc"]
  tf_managed_comment = "Managed by TF"
  stack_tags         = {}

  # computed
  tags = merge(var.global_tags, local.stack_tags)
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~>0.4.0"
}
module "naming_extras" {
  source = "../../modules/naming-extras"
}
module "location" {
  source   = "azurerm/locations/azure"
  version  = "~>0.2.4"
  location = var.azure_region
}

data "azurerm_databricks_workspace" "dev" {
  name                = var.databricks_workspace_dev.name
  resource_group_name = var.databricks_workspace_dev.resource_group_name
}
data "azurerm_databricks_workspace" "prd" {
  name                = var.databricks_workspace_prd.name
  resource_group_name = var.databricks_workspace_prd.resource_group_name
}

locals {
  databricks_workspace_ids = [
    data.azurerm_databricks_workspace.dev.id,
    data.azurerm_databricks_workspace.prd.id
  ]
}

# Unity Catalog
resource "databricks_group" "unity_catalog_admins" {
  display_name = "unity-catalog-admins"
}

resource "databricks_metastore" "this" {
  name          = join("-", [local.workload_uc, module.locations.location.short_name])
  region        = module.location.location
  force_destroy = false
  owner         = databricks_group.unity_catalog_admins.display_name
}
resource "databricks_metastore_assignment" "this" {
  for_each = toset(local.databricks_workspace_ids)

  metastore_id = databricks_metastore.this.id
  workspace_id = each.value
}

