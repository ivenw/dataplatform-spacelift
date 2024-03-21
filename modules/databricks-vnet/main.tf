terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}
variable "address_space" {
  type = string
}
variable "resource_names" {
  type = object({
    vnet         = object({ name = string })
    nsg          = object({ name = string })
    snet_private = object({ name = string })
    snet_public  = object({ name = string })
  })
}

locals {
  service_delegation_actions = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
    "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
  ]
}

resource "azurerm_virtual_network" "this" {
  name                = var.resource_names["vnet"].name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  address_space       = [var.address_space]
}

resource "azurerm_network_security_group" "this" {
  name                = var.resource_names["nsg"].name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_subnet" "private" {
  name                 = var.resource_names["snet_private"].name
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.address_space, 1, 0)]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "databricks"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = local.service_delegation_actions
    }
  }
}

resource "azurerm_subnet" "public" {
  name                 = var.resource_names["snet_public"].name
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.address_space, 1, 1)]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "databricks"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = local.service_delegation_actions
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.this.id
}

output "vnet" {
  value = azurerm_virtual_network.this
}
output "nsg" {
  value = azurerm_network_security_group.this
}
output "snet_private" {
  value = azurerm_subnet.private
}
output "snet_public" {
  value = azurerm_subnet.public
}
output "nsga_private" {
  value = azurerm_subnet_network_security_group_association.private
}
output "nsga_public" {
  value = azurerm_subnet_network_security_group_association.public
}

