terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~>1.10.0"
    }
  }
}

variable "name" {
  description = "The name of the stack"
  type        = string
}
variable "space_id" {
  description = "The ID of the space resource the stack should be created in"
  type        = string
}
variable "repository" {
  description = "The repository the stack should be created from"
  type        = string
}
variable "project_root" {
  description = "The root directory of the project"
  type        = string
  default     = null
}
variable "branch" {
  description = "The branch of the repository the stack should be created from"
  type        = string
  default     = "main"
}
variable "labels" {
  description = "The labels to add to the stack"
  type        = list(string)
  default     = []
}
variable "dependencies" {
  description = "Other stacks this stack depends on"
  type = list(object({
    stack_id   = string
    references = map(string)
  }))
  default = []
}

locals {
  terraform_workflow_tool = "OPEN_TOFU"
  terraform_version       = "1.6.2"
}

resource "spacelift_stack" "this" {
  name     = var.name
  space_id = var.space_id

  repository              = var.repository
  branch                  = var.branch
  project_root            = var.project_root
  terraform_workflow_tool = local.terraform_workflow_tool
  terraform_version       = local.terraform_version

  autodeploy = true
  labels     = var.labels
}

resource "spacelift_stack_dependency" "this" {
  // Count is not ideal in this case, but the only way to make this work.
  // Reordering dependencies in input will lead to recreation of these resources,
  // but this doesn't really matter in this instance, since its stateless configuration.
  count = length(var.dependencies)

  stack_id            = spacelift_stack.this.id
  depends_on_stack_id = var.dependencies[count.index].stack_id
}

locals {
  dependencies = flatten([
    for dependency in var.dependencies : [
      for output_name, input_name in dependency.references : {
        index       = index(var.dependencies, dependency)
        stack_id    = dependency.stack_id
        output_name = output_name
        input_name  = input_name
      }
    ]
  ])
}

resource "spacelift_stack_dependency_reference" "this" {
  // Count is not ideal in this case, but the only way to make this work.
  // Reordering dependencies in input will lead to recreation of these resources,
  // but this doesn't really matter in this instance, since its stateless configuration.
  count = length(local.dependencies)

  stack_dependency_id = spacelift_stack_dependency.this[local.dependencies[count.index].index].id
  output_name         = local.dependencies[count.index].output_name
  input_name          = local.dependencies[count.index].input_name
}

output "stack_id" {
  value = spacelift_stack.this.id
}

