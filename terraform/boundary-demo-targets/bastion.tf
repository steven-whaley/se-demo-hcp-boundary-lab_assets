resource "aws_instance" "bastion" {
  ami           = data.aws_ami.aws_linux_hvm2.id
  instance_type = "t3.micro"

  ebs_block_device {
    volume_type = "gp2"
    volume_size = "10"
    device_name = "/dev/sdf"
  }

  key_name                    = aws_key_pair.boundary_ec2_keys.key_name
  monitoring                  = true
  subnet_id                   = data.terraform_remote_state.boundary_demo_init.outputs.pub_subnet_id
  vpc_security_group_ids      = [module.bastion-sec-group.security_group_id]
}

#Create worker EC2 security group
module "bastion-sec-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name   = "boundary-bastion-sec-group"
  vpc_id = data.terraform_remote_state.boundary_demo_init.outputs.vpc_id
  
  egress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      description = "Allow SSH to SSH target"
      source_security_group_id = module.worker-sec-group.security_group_id
    }
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = ["ssh-tcp"]
}