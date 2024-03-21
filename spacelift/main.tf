import {
  to = spacelift_stack.spacelift
  id = "spacelift"
}

resource "spacelift_stack" "spacelift" {
  name     = "spacelift"
  space_id = "root"

  repository   = "dataplatform-spacelift"
  branch       = "main"
  project_root = "spacelift"

  administrative = true
  autodeploy     = true
}

resource "spacelift_space" "dataplatform" {
  name            = "dataplatform"
  parent_space_id = "root"
}

resource "spacelift_stack" "databricks_dev" {
  name     = "databricks-dev"
  space_id = spacelift_space.dataplatform.id

  repository   = "dataplatform-spacelift"
  branch       = "main"
  project_root = "stacks/databricks-workspace"
}
