locals {
  databricks_access_connector = {
    slug       = "dbac"
    dashes     = true
    scope      = ""
    max_length = 64
  }
}

output "databricks_access_connector" {
  value = local.databricks_access_connector
}

