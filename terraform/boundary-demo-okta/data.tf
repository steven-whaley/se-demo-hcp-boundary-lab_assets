data "terraform_remote_state" "boundary_demo_targets" {
  backend = "local"

  config = {
    path = "../boundary-demo-targets/terraform.tfstate"
  }
}

data "terraform_remote_state" "boundary_demo_init" {
  backend = "local"

  config = {
    path = "../boundary-demo-init/terraform.tfstate"
  }
}