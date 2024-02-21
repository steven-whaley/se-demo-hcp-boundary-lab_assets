terraform {
  required_providers {
    aws = {
      version = "5.31.0"
      source  = "hashicorp/aws"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.79.0"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.12"
    }
    vault = {
      version = "3.23.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "tfe" {}

provider "boundary" {
  addr                   = data.terraform_remote_state.boundary_demo_init.outputs.boundary_url
  auth_method_id         = data.terraform_remote_state.boundary_demo_init.outputs.boundary_admin_auth_method
  auth_method_login_name = "admin"
  auth_method_password   = data.terraform_remote_state.boundary_demo_init.outputs.boundary_admin_password
}

provider "vault" {
  address = data.terraform_remote_state.boundary_demo_init.outputs.vault_pub_url
  auth_login_userpass {
    username = "terraform"
    password = data.terraform_remote_state.boundary_demo_init.outputs.vault_password
  }
}

provider "hcp" {}