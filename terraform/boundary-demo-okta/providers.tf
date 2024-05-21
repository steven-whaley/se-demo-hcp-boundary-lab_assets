terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.15"
    }
    okta = {
      source  = "okta/okta"
      version = "4.6.3"
    }
  }
}

provider "boundary" {
  addr                   = data.terraform_remote_state.boundary_demo_init.outputs.boundary_url
  auth_method_id         = data.terraform_remote_state.boundary_demo_init.outputs.boundary_admin_auth_method
  auth_method_login_name = "admin"
  auth_method_password   = data.terraform_remote_state.boundary_demo_init.outputs.boundary_admin_password
}