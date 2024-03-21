terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~>1.10.0"
    }
  }
}

provider "spacelift" {}

