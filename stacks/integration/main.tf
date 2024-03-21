variable "test" {
  type = object({
    env      = string
    location = string
  })
}

output "test" {
  value = var.test
}

