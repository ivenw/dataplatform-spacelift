variable "container_name" {
  description = "The name of the container."
  type        = string
}
variable "storage_account_name" {
  description = "The name of the storage account."
  type        = string
}
variable "path" {
  description = "The path to the file."
  type        = string
  default     = "/"
  validation {
    condition     = startswith(var.path, "/")
    error_message = "The path must start with a forward slash."
  }
}

locals {
  abfss_url_template = "abfss://%s@%s.dfs.core.windows.net%s"
  abfss_url          = format(local.abfss_url_template, var.container_name, var.storage_account_name, var.path)
}

output "abfss_url" {
  value = local.abfss_url
}

