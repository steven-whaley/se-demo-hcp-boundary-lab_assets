# Get the default userpass auth method ID from the HCP cluster
data "http" "boundary_cluster_auth_methods" {
  url = "${hcp_boundary_cluster.boundary-demo.cluster_url}/v1/auth-methods?filter=%22password%22+in+%22%2Fitem%2Ftype%22&scope_id=global"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "aws_linux_hvm2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "vault-init" {
  template = file("${path.module}/vault_user_data.tftpl")
  vars = {
    vaultpass = random_string.vault_pass.result
  }
}