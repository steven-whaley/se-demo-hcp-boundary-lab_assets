variable "admin_pass" {
  type        = string
  description = "The password to set on the windows and linux targets for the admin user"
  default = "LongPassword123"
}

variable "region" {
  type        = string
  description = "The AWS region into which to deploy the HVN"
  default = "us-west-2"
}