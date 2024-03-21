variable "environment_slug" {
    description = "The environment slug"
    type        = string
}

output "environment_slug" {
    value = var.environment_slug
}

