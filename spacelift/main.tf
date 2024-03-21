resource "spacelift_stack" "databricks_dev" {
  name       = "databricks-dev"
  repository = "dataplatform-spacelift"
  branch     = "main"
}
