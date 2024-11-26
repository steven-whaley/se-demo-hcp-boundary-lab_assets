resource "random_password" "db_password" {
  length  = 12
  special = false
}

resource "aws_instance" "k8s_cluster" {
  lifecycle {
    ignore_changes = [user_data]
  }
  depends_on                  = [vault_ssh_secret_backend_ca.ssh_ca, aws_ssm_parameter.cert, aws_ssm_parameter.token]
  associate_public_ip_address = false
  ami                         = data.aws_ami.aws_linux_hvm2.id
  subnet_id                   = data.terraform_remote_state.boundary_demo_init.outputs.priv_subnet_id
  instance_type               = "t3.medium"
  vpc_security_group_ids      = [module.k8s-sec-group.security_group_id]
  key_name                    = aws_key_pair.boundary_ec2_keys.key_name
  iam_instance_profile        = aws_iam_instance_profile.ssm_write_profile.name
  
  root_block_device {
    volume_size = "10"
    volume_type = "gp3"
  }
  
  user_data = templatefile("./template_files/k8s-cloudinit.tftpl", {
    password        = random_password.db_password.result,
    vault_namespace = vault_namespace.pie.path_fq
    vault_url       = data.terraform_remote_state.boundary_demo_init.outputs.vault_priv_url
    vault_ssh_mount = vault_mount.ssh.path
  })
  
  tags = {
    Name   = "k8s-cluster"
    app    = "kubernetes"
    region = "${var.region}"
  }
}

module "k8s-sec-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "k8s-sec-group"
  vpc_id = data.terraform_remote_state.boundary_demo_init.outputs.vpc_id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  ingress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      description              = "Allow SSH to SSH target"
      source_security_group_id = module.worker-sec-group.security_group_id
    },
    {
      rule                     = "kubernetes-api-tcp"
      description              = "Allow K8s access on K8s target"
      source_security_group_id = module.worker-sec-group.security_group_id
    },
    {
      from_port                = 30932
      to_port                  = 30932
      protocol                 = "tcp"
      description              = "Allow Postgres access on exposed port"
      source_security_group_id = module.worker-sec-group.security_group_id
    },
    {
      from_port                = 30932
      to_port                  = 30932
      protocol                 = "tcp"
      description              = "Allow Postgres access on exposed port"
      source_security_group_id = data.terraform_remote_state.boundary_demo_init.outputs.vault_sec_group
    },
    {
      rule                     = "kubernetes-api-tcp"
      description              = "Allow K8s access on K8s target"
      source_security_group_id = data.terraform_remote_state.boundary_demo_init.outputs.vault_sec_group
    },
    {
      from_port                = 30080
      to_port                  = 30080
      protocol                 = "tcp"
      description              = "Allow web access to Wiki from worker"
      source_security_group_id = module.worker-sec-group.security_group_id
    },
  ]
}