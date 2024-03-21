data "spacelift_current_space" "this" {}

resource "spacelift_stack" "spacelift" {
  name     = "spacelift"
  space_id = data.spacelift_current_space.this.id

  repository   = "dataplatform-spacelift"
  branch       = "main"
  project_root = "spacelift"

  administrative = true
  autodeploy     = true
}

resource "spacelift_space" "dataplatform" {
  name            = "dataplatform"
  parent_space_id = data.spacelift_current_space.this.id
  description     = "All stacks for the data platform"
}

resource "spacelift_context" "global" {
  name        = "global"
  space_id    = spacelift_space.dataplatform.id
  description = "Global context"
  labels      = ["autoattach:global"]
}
resource "spacelift_environment_variable" "location" {
  context_id = spacelift_context.global.id
  name       = "TF_VAR_location"
  value      = "westeurope"
  write_only = false
}

resource "spacelift_context" "environment_dev" {
  name        = "environment-dev"
  space_id    = spacelift_space.dataplatform.id
  description = "Development environment context"
  labels      = ["autoattach:dev"]
}
resource "spacelift_environment_variable" "environment_dev" {
  context_id = spacelift_context.environment_dev.id
  name       = "TF_VAR_environment_slug"
  value      = "dev"
  write_only = false
}

resource "spacelift_stack" "databricks_dev" {
  name     = "databricks-dev"
  space_id = spacelift_space.dataplatform.id

  repository   = "dataplatform-spacelift"
  branch       = "main"
  project_root = "stacks/databricks-workspace"

  labels = ["global", "dev"]
}
