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

module "stack_databricks_workspace_dev" {
  source = "../modules/spacelift-stack"

  name     = "databricks-dev"
  space_id = spacelift_space.dataplatform.id

  repository   = "dataplatform-spacelift"
  project_root = "stacks/databricks-workspace"
  labels       = ["global", "dev"]
}

module "test" {
  source = "../modules/spacelift-stack"

  name     = "test"
  space_id = spacelift_space.dataplatform.id

  repository   = "dataplatform-spacelift"
  project_root = "stacks/integration"
  labels       = ["global", "dev"]

  dependencies = [
    {
      stack_id = module.stack_databricks_workspace_dev.stack_id
      references = {
        env = "TF_VAR_test"
      }
    }
  ]
}

