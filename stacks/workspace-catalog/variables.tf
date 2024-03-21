# Provider settings
variable "tenant_id" {
  description = "The ID of the tenant"
  type        = string
  sensitive   = true
}
variable "subscription_id" {
  description = "The ID of the subscription"
  type        = string
  sensitive   = true
}

# Global settings
variable "application_name" {
  description = "The name of the application"
  type        = string
}
variable "azure_region" {
  description = "The region where the resources will be created"
  type        = string
}
variable "global_tags" {
  description = "The global tags for all resources"
  type        = map(string)
  default     = {}
}

# Dependencies
variable "databricks_workspace" {
  description = "The primary Databricks workspace for the catalog"
  type = object({
    id            = string
    workspace_url = string
  })
}

# Stack settings
variable "catalog_root_name" {
  description = "The root of the catalog name, i.e. 'lakehouse'"
  type        = string
}
variable "catalog_owner" {
  description = "Databricks group/user id of catalog owner"
  type = object({
    id = string
  })
}
variable "environment_slug" {
  description = "The environment where the resources will be created"
  type        = string
  validation {
    condition     = var.environment_sluge == lower(var.environment_slug)
    error_message = "The environment slug must be lowercase"
  }
}
variable "global tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

