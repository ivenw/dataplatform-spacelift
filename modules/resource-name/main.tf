terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
}

variable "naming_data" {
  description = "Naming information from the terraform-azure-naming module."
  type = object({
    slug       = string
    dashes     = bool
    scope      = string
    max_length = number
  })
}
variable "location_data" {
  description = "Location information from the terraform-azure-locations module."
  type = object({
    short_name = string
  })
}
variable "application" {
  description = "The name of the application."
  type        = string
}
variable "workload" {
  description = "The name of the workload."
  type        = list(string)
  default     = []
}
variable "environment" {
  description = "The name of the environment."
  type        = string
  default     = ""
  validation {
    condition     = contains(["dev", "tst", "prd", "stg", "uat"], var.environment)
    error_message = "The environment must be one of: dev, tst, prd, stg, uat."
  }
}

data "azurerm_subscription" "current" {}

locals {
  guid_seed = [
    data.azurerm_subscription.current.id,
    var.application,
    var.location_data.short_name,
    var.environment
  ]
  guid                = md5(join("", local.guid_seed))
  guid_short          = substr(local.guid, 0, 4)
  scope_requires_guid = contains(["global", "region"], var.naming_data.scope)
  name_list = compact(flatten([
    var.naming_data.slug,
    var.application,
    var.workload,
    local.scope_requires_guid ? local.guid_short : "",
    var.location_data.short_name,
    var.environment
  ]))
  name_w_dashes  = join("-", local.name_list)
  name_wo_dashes = join("", local.name_list)
  name           = var.naming_data.dashes ? local.name_w_dashes : local.name_wo_dashes

  name_length = length(local.name)
}

output "name" {
  value = local.name

  precondition {
    condition     = local.name_length <= var.naming_data.max_length
    error_message = "The name of the resource is too long. ${local.name_length} characters are used, but only ${var.naming_data.max_length} are allowed."
  }
}

