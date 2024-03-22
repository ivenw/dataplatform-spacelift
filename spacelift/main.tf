data "spacelift_current_space" "this" {}

locals {
  terraform_workflow_tool     = "OPEN_TOFU"
  terraform_version           = "1.6.2"
  repository                  = "dataplatform-spacelift"
  environment_slugs_resources = ["dev", "prd"]
  environment_slugs_catalogs  = ["dev", "stg", "prd"]
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

module "context_environment_resources" {
  source   = "../modules/spacelift-context"
  for_each = toset(local.environment_slugs_resources)

  name        = "environment-${each.key}"
  space_id    = spacelift_space.dataplatform.id
  description = "Development environment context"
  labels      = ["autoattach:${each.key}"]
  environment_variables = {
    TF_VAR_environment_slug = each.key
  }
}

module "stack_integration" {
  source   = "../modules/spacelift-stack"
  for_each = toset(local.environment_slugs_resources)

  name     = "integration-${each.key}"
  space_id = spacelift_space.dataplatform.id

  repository   = local.repository
  project_root = "stacks/integration"
  labels = concat(
    module.context_global.autoattach_labels,
    module.context_environment_resources[each.key].autoattach_labels
  )
}

module "stack_databricks_workspace" {
  source   = "../modules/spacelift-stack"
  for_each = toset(local.environment_slugs_resources)

  name     = "databricks-${each.key}"
  space_id = spacelift_space.dataplatform.id

  repository   = local.repository
  project_root = "stacks/databricks-workspace"
  labels = concat(
    module.context_global.autoattach_labels,
    module.context_environment_resources[each.key].autoattach_labels
  )
}

