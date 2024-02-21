# Create EC2 key pair using public key provided in variable
resource "aws_key_pair" "boundary_ec2_keys" {
  key_name   = "boundary-demo-ec2-key"
  public_key = var.public_key
}

resource "aws_iam_instance_profile" "ssm_write_profile" {
  name = "ssm-write-profile"
  role = aws_iam_role.ssm_write_role.name
}

data "aws_iam_policy_document" "ssm_write_policy" {
  statement {
    effect = "Allow"
    actions = ["ssm:PutParameter"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "boundary-demo-ssm-policy"
  description = "Policy used in Boundary demo to write kube info to SSM"
  policy      = data.aws_iam_policy_document.ssm_write_policy.json
}

resource "aws_iam_role" "ssm_write_role" {
  
  name = "ssm_write_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "ssm_write_policy" {
  name = "boundary-demo-ssm-policy-attachment"
  roles = [aws_iam_role.ssm_write_role.name]
  policy_arn = aws_iam_policy.ssm_policy.arn
}

# Create Parameter store entries so that TF can delete them on teardown

resource "aws_ssm_parameter" "cert" {
  lifecycle {
    ignore_changes = [ value ]
  }
  name  = "cert"
  type  = "String"
  value = "placeholder"
}

resource "aws_ssm_parameter" "token" {
  lifecycle {
    ignore_changes = [ value ]
  }
  name  = "token"
  type  = "String"
  value = "placeholder"
}

# Create bucket for session recording
resource "random_string" "boundary_bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "boundary_recording_bucket" {
  bucket        = "boundary-recording-bucket-${random_string.boundary_bucket_suffix.result}"
  force_destroy = true
}