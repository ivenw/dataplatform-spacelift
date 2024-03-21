terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=> 3.83"
    }
    azapi = {
      source  = "azure/azapi"
      version = "=> 1.10"
    }
  }
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}
variable "name" {
  description = "The name of the storage account."
  type        = string
}
variable "container_names" {
  description = "List of names of the blob containers to create."
  type        = list(string)
  default     = []
}
variable "allowed_subnets" {
  description = "List of subnets that are allowed to access the storage account."
  type = list(object({
    id = string
  }))
  default = []
}
variable "private_link_resources" {
  description = "List of resources that are allowed to access the storage account via private link."
  type = list(object({
    id = string
  }))
  default = []
}
variable "prevent_destroy" {
  description = "Prevent the storage account from being destroyed."
  type        = bool
  default     = true
}
variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

resource "azurerm_storage_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  account_tier        = "Standard"
  is_hns_enabled      = true
  tags                = var.tags

  # Replication and retention settings
  account_replication_type = "ZRS"

  # Security settings
  public_access_enabled           = false
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  local_users_enabled             = false

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = [for subnet in var.allowed_subnets : subnet.id]

    dynamic "private_link_access" {
      for_each = var.private_link_resources

      content {
        endpoint_resource_id = private_link_access.value.id
      }
    }
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

// We have to use the azapi provider because the storage account does not permit public access
// and the azurerm provider does not support creating blob containers without public access.
resource "azapi_resource" "blob_containers" {
  for_each  = toset(var.container_names)
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01"
  name      = each.value
  parent_id = "${azurerm_storage_account.this.id}/blobServices/default"
  body = jsonencode({
    properties = {
      defaultEncryptionScope      = "$account-encryption-key"
      denyEncryptionScopeOverride = false
      metadata                    = {}
      publicAccess                = "None"
    }
  })
}


output "storage_account" {
  value = azurerm_storage_account.this
}
output "containers" {
  // list of blob containers with their names
  value = [
    for container_name in var.container_names : { name = container_name }
  ]
}
