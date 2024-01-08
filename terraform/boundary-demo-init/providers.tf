terraform {
  required_version = ">= 1.0"
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.79.0"
    }
  }
}

provider "hcp" {}
