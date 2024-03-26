terraform {
  required_version = "~>1.6.2"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~>1.10.0"
    }
  }
}

provider "spacelift" {}

