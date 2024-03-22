terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~>1.10.0"
    }
  }
}

variable "name" {
  description = "The name of the context"
  type        = string
}
variable "description" {
  description = "The description of the context"
  type        = string
}
variable "space_id" {
  description = "The ID of the space resource the context should be created in"
  type        = string
}
variable "labels" {
  description = "The labels to add to the context"
  type        = list(string)
  default     = null
}
variable "environment_variables" {
  description = "Non-secret environment variables to add to the context"
  type        = map(string)
  default     = {}
}

resource "spacelift_context" "this" {
  name        = var.name
  space_id    = var.space_id
  description = var.description
  labels      = var.labels
}
resource "spacelift_environment_variable" "location" {
  for_each = var.environment_variables

  context_id = spacelift_context.this.id
  name       = each.key
  value      = each.value
  write_only = false
}

locals {
  autoattach_label_pattern = "autoattach:(.*)"
  autoattach_labels = [
    for label in var.labels :
    can(regex(local.autoattach_label_pattern, label))
    ? regex(local.autoattach_label_pattern, label)[0] : null
  ]
}

output "autoattach_labels" {
  value = local.autoattach_labels
}
