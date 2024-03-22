data "spacelift_current_space" "this" {}

locals {
  terraform_workflow_tool = "OPEN_TOFU"
  terraform_version       = "1.6.2"
  repository              = "dataplatform-spacelift"
}

resource "spacelift_stack" "spacelift" {
  name     = "spacelift"
  space_id = data.spacelift_current_space.this.id

  repository              = local.repository
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

module "context_global" {
  source = "../modules/spacelift-context"

  name        = "global"
  space_id    = spacelift_space.dataplatform.id
  description = "Global context"
  labels      = ["autoattach:global"]
  environment_variables = {
    TF_VAR_location = "westeurope"
  }
}

module "context_environment_dev" {
  source = "../modules/spacelift-context"

  name        = "environment-dev"
  space_id    = spacelift_space.dataplatform.id
  description = "Development environment context"
  labels      = ["autoattach:dev"]
  environment_variables = {
    TF_VAR_environment_slug = "dev"
  }
}

module "context_environment_prd" {
  source = "../modules/spacelift-context"

  name        = "environment-prd"
  space_id    = spacelift_space.dataplatform.id
  description = "prdelopment environment context"
  labels      = ["autoattach:prd"]
  environment_variables = {
    TF_VAR_environment_slug = "prd"
  }
}

module "stack_integration_dev" {
  source = "../modules/spacelift-stack"

  name     = "integration-dev"
  space_id = spacelift_space.dataplatform.id

  repository   = local.repository
  project_root = "stacks/integration"
  labels = concat(
    module.context_global.autoattach_labels,
    module.context_environment_dev.autoattach_labels
  )
}

module "stack_databricks_workspace_dev" {
  source = "../modules/spacelift-stack"

  name     = "databricks-dev"
  space_id = spacelift_space.dataplatform.id

  repository   = local.repository
  project_root = "stacks/databricks-workspace"
  labels = concat(
    module.context_global.autoattach_labels,
    module.context_environment_dev.autoattach_labels
  )
}

