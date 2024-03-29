resource "random_pet" "pet_name" {
}

resource "random_pet" "random_password" {
  length = 2
}

#Create New HCP Project for these resources
resource "hcp_project" "project" {
  name        = "instruqt-${random_pet.pet_name.id}"
  description = "Project Created by Instruqt Boundary Demo Lab"
}

#Create HCP Boundary Cluster
resource "hcp_boundary_cluster" "boundary-demo" {
  project_id = hcp_project.project.resource_id
  cluster_id = "instruqt-${random_pet.pet_name.id}"
  username   = "admin"
  password   = random_pet.random_password.id
  tier       = "PLUS"
}

resource "random_string" "vault_pass" {
  length  = 12
  special = false
}

#Create AWS Public key pair
resource "aws_key_pair" "vault_key" {
  key_name = "vault-key"
  public_key = var.public_key
}

#Create VPC and subnets for EC2 instances
module "boundary-demo-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "boundary-demo-vpc"
  cidr = "10.1.0.0/16"

  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
}

#Create Security Group for Vault instance
module "vault-security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "vault-server-access"
  description = "Allow connection to Vault API"
  vpc_id      = module.boundary-demo-vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 8200
      to_port     = 8200
      protocol    = "tcp"
      description = "Connect to Vault UI/API"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      description = "Allow egress to everything within VPC"
      cidr_blocks = module.boundary-demo-vpc.vpc_cidr_block
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["https-443-tcp", "http-80-tcp"]
}


#Create Vault server EC2 instance with AWS Linux AMI
resource "aws_instance" "vault-server" {
  ami           = data.aws_ami.aws_linux_hvm2.id
  instance_type = "t3.micro"

  key_name                    = aws_key_pair.vault_key.key_name
  monitoring                  = true
  subnet_id                   = module.boundary-demo-vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.vault-security-group.security_group_id]
  user_data            = templatefile("${path.module}/vault_user_data.tftpl", { vaultpass = random_string.vault_pass.id, vault_license=var.vault_license })

  tags = {
    Name = "vault-demo"
  }
}