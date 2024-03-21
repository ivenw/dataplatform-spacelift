data "spacelift_current_space" "this" {}

locals {
  terraform_workflow_tool = "OPEN_TOFU"
  terraform_version       = "1.6.2"
}

resource "spacelift_stack" "spacelift" {
  name     = "spacelift"
  space_id = data.spacelift_current_space.this.id

  repository              = "dataplatform-spacelift"
  branch                  = "main"
  project_root            = "spacelift"
  terraform_workflow_tool = local.terraform_workflow_tool
  terraform_version       = local.terraform_version

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

  repository              = "dataplatform-spacelift"
  branch                  = "main"
  project_root            = "stacks/databricks-workspace"
  terraform_workflow_tool = local.terraform_workflow_tool
  terraform_version       = local.terraform_version

  autodeploy = true
  labels     = ["global", "dev"]
}

resource "spacelift_stack" "test" {
  name     = "test"
  space_id = spacelift_space.dataplatform.id

  repository              = "dataplatform-spacelift"
  branch                  = "main"
  project_root            = "stacks/integration"
  terraform_workflow_tool = local.terraform_workflow_tool
  terraform_version       = local.terraform_version

  autodeploy = true
  labels     = ["global", "dev"]
}

resource "spacelift_stack_dependency" "databricks_dev_test" {
  stack_id      = spacelift_stack.test.id
  depends_on_id = spacelift_stack.databricks_dev.id
}

resource "spacelift_stack_dependency_reference" "databricks_dev_test" {
  stack_dependency_id = spacelift_stack_dependency.databricks_dev_test.id
  output_name         = "env"
  input_name          = "TF_VAR_test"
}

