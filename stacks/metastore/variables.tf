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
variable "databricks_account_id" {
  description = "The ID of the Databricks account"
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
variable "databricks_workspace_id_dev" {
  type = string
}
variable "databricks_workspace_id_prd" {
  type = string
}

