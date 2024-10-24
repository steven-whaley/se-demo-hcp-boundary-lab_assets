data "aws_availability_zones" "available" {
  state = "available"
}
# data "aws_ami" "aws_linux_hvm2" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-kernel-5.10-hvm-2*"]
#   }

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

data "aws_ami" "aws_linux_hvm2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "terraform_remote_state" "boundary_demo_init" {
  backend = "local"

  config = {
    path = "../boundary-demo-init/terraform.tfstate"
  }
}