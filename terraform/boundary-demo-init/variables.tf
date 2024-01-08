variable "boundary_user" {
  type = string
  default = "admin"
}

variable "region" {
  type        = string
  default = "us-west-2"
  description = "The AWS region into which to deploy the HVN"
}