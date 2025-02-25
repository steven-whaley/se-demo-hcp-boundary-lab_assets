resource "random_uuid" "worker_uuid" {}

resource "boundary_worker" "hcp_pki_worker" {
  scope_id                    = "global"
  name                        = "boundary-worker-${random_uuid.worker_uuid.result}"
  worker_generated_auth_token = ""
}

locals {
  boundary_worker_config = <<-WORKER_CONFIG
    hcp_boundary_cluster_id = "${split(".", split("//", data.terraform_remote_state.boundary_demo_init.outputs.boundary_url)[1])[0]}"
    listener "tcp" {
      purpose = "proxy"
      address = "0.0.0.0"
    }
    worker {
      auth_storage_path = "/boundary/boundary-worker-${random_uuid.worker_uuid.result}"
      controller_generated_activation_token = "${boundary_worker.hcp_pki_worker.controller_generated_activation_token}"
      recording_storage_path="/boundary/storage/"
      recording_storage_minimum_available_capacity = "10MB"
      tags {
        type = "public_instance"
        cloud = "aws"
        region = "${var.region}"
      }
    }
    WORKER_CONFIG

  cloudinit_config_boundary_worker = {
    write_files = [
      {
        content     = local.boundary_worker_config
        owner       = "root:root"
        path        = "/run/boundary/config.hcl"
        permissions = "0644"
      },
    ]
    runcmd = [
      ["yum", "update", "-y"],
      ["yum", "install", "-y", "docker"],
      ["systemctl", "start", "docker"],
      ["docker", "run", "-p", "9202:9202", "-v", "/run/boundary:/boundary/", "hashicorp/boundary-enterprise", "boundary", "server", "-config", "/boundary/config.hcl"]
    ]
  }
}

data "cloudinit_config" "boundary_worker" {
  gzip          = false
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.cloudinit_config_boundary_worker)
  }
}

resource "aws_instance" "worker" {
  lifecycle {
    ignore_changes = [user_data_base64]
  }

  depends_on = [
    boundary_worker.hcp_pki_worker, aws_key_pair.boundary_ec2_keys
  ]

  ami           = data.aws_ami.aws_linux_hvm2.id
  instance_type = "t3.micro"

  ebs_block_device {
    volume_type = "gp2"
    volume_size = "40"
    device_name = "/dev/sdf"
  }

  key_name                    = aws_key_pair.boundary_ec2_keys.key_name
  monitoring                  = true
  subnet_id                   = data.terraform_remote_state.boundary_demo_init.outputs.priv_subnet_id
  vpc_security_group_ids      = [module.worker-sec-group.security_group_id]
  user_data_base64            = data.cloudinit_config.boundary_worker.rendered
  user_data_replace_on_change = false

  tags = {
    Name = "boundary-worker-${random_uuid.worker_uuid.result}"
  }
}

#Create worker EC2 security group
module "worker-sec-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name   = "boundary-worker-sec-group"
  vpc_id = data.terraform_remote_state.boundary_demo_init.outputs.vpc_id
  
  ingress_with_source_security_group_id = [
    {
      rule = "ssh-tcp"
      source_security_group_id = module.bastion-sec-group.security_group_id
    }
  ]


  egress_with_cidr_blocks = [
    {
      from_port   = 9202
      to_port     = 9202
      protocol    = "tcp"
      description = "Worker to HCP Boundary Control plane"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      description = "Allow SSH to SSH target"
      source_security_group_id = module.k8s-sec-group.security_group_id
    },
    {
      rule = "rdp-tcp"
      description = "Allow RDP to RDP target"
      source_security_group_id = module.rdp-sec-group.security_group_id
    },
    {
      rule                     = "kubernetes-api-tcp"
      description = "Allow K8s access on K8s target"
      source_security_group_id = module.k8s-sec-group.security_group_id
    },
    {
      from_port = 30932
      to_port = 30932
      protocol = "tcp"
      description = "Allow Postgres access on exposed port"
      source_security_group_id = module.k8s-sec-group.security_group_id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["https-443-tcp", "http-80-tcp"]
}