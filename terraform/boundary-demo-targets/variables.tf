variable "admin_pass" {
  type        = string
  default     = "LongPassword123"
  description = "The password to set on the windows target for the admin user"
}

variable "region" {
  type        = string
  description = "The region to create instrastructure in"
  default     = "us-west-2"
}

variable "public_key" {
  type        = string
  description = "The public key to use when creating the EC2 key pair to access AWS systems"
}

variable "use_okta" {
  description = "Variable that controls whether we are using Okta as part of the demo or not"
  type        = bool
  default     = false
}