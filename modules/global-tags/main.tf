locals {
  tags = {
    managed_by = "spacelift"
  }
}

output "tags" {
  value = local.tags
}

