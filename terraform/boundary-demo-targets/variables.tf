variable "admin_pass" {
  type        = string
  default = "LongPassword123"
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

variable "okta_baseurl" {
  description = "The base url for the Okta organization used for OIDC integration. Probably okta.com"
  type        = string
}

variable "okta_org_name" {
  description = "The organization name for the Okta organization use for OIDC integration i.e. dev-32201783"
  type        = string
}