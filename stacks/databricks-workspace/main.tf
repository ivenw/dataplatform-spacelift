variable "environment_slug" {
  description = "The environment slug"
  type        = string
}
variable "location" {
  description = "The location of the resource"
  type        = string
}

output "environment_slug" {
  value = var.environment_slug
}

output "env" {
  value = {
    env      = var.environment_slug
    location = var.location
  }
}


