# Windows Target

resource "aws_instance" "rdp-target" {
  ami           = data.aws_ami.windows.id
  instance_type = "t3.small"

  key_name               = aws_key_pair.boundary_ec2_keys.key_name
  monitoring             = true
  subnet_id              = data.terraform_remote_state.boundary_demo_init.outputs.priv_subnet_id
  vpc_security_group_ids = [module.rdp-sec-group.security_group_id]
  user_data              = templatefile("./template_files/windows-target.tftpl", { admin_pass = var.admin_pass })
  tags = {
    Team = "IT"
    Name = "rdp-target"
  }
}

module "rdp-sec-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name        = "rdp-sec-group"
  description = "Allow Access from Boundary Worker and Vault to RDP target"
  vpc_id      = data.terraform_remote_state.boundary_demo_init.outputs.vpc_id
  ingress_with_source_security_group_id = [
    {
      rule                     = "rdp-tcp"
      source_security_group_id = module.worker-sec-group.security_group_id
    },
    {
      rule                     = "all-all"
      source_security_group_id = data.terraform_remote_state.boundary_demo_init.outputs.vault_sec_group
    },
  ]
}
