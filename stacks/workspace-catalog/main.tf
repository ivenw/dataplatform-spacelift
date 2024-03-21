locals {
  uc_container_name     = "unity-catalog"
  storage_root_template = "abfss://%@%.dfs.core.windows.net/"
  managed_by_tf         = "Managed by TF"
  stack_tags            = {}

  workload          = [var.catalog_root_name]
  catalog_full_name = join("_", [var.catalog_root_name, var.environment_slug])
  storage_root = format(
    local.storage_root_template, local.uc_container_name, module.st.storage_account.name
  )
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
module "resource_names" {
  source = "../../modules/resource-name"

  for_each = {
    rg   = module.naming.resource_group,
    st   = module.naming.storage_account,
    dbac = module.naming_extras.databricks_access_connector,
  }

  application   = var.application_name
  workload      = local.workload
  environment   = var.environment_slug
  naming_data   = each.value
  location_data = module.locations
}

resource "azurerm_resource_group" "this" {
  name     = module.resource_names["rg"].name
  location = module.locations.location
}

module "st_dev" {
  source = "../../modules/lake-storage"

  resource_group         = azurerm_resource_group.this
  name                   = module.resource_names["st"].name
  container_names        = [local.uc_container_name]
  private_link_resources = [azurerm_databricks_access_connector.this]
  prevent_destroy        = true
  tags                   = local.tags
}

resource "azurerm_databricks_access_connector" "this" {
  name                = module.resource_names["dbac"].name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

resource "azurerm_role_assignment" "this" {
  scope                = var.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this.identity[0].principal_id
}

resource "databricks_catalog" "this" {
  name           = local.catalog_full_name
  storage_root   = local.storage_root
  isolation_mode = "ISOLATED"
}

resource "databricks_storage_credential" "this" {
  name = azurerm_databricks_access_connector.this.name
  azure_managed_identity {
    principal_id = azurerm_databricks_access_connector.this.id
  }
  owner   = var.catalog_owner.id
  comment = local.managed_by_tf
}

resource "databricks_external_location" "this" {
  name            = local.catalog_full_name
  url             = local.storage_root
  credential_name = databricks_storage_credential.this.id
  owner           = var.catalog_owner.id
  comment         = local.managed_by_tf
}

