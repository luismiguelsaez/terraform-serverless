# AWS Provider settings
variable "aws_profile_name" {
  type    = string
  default = "dev-admin"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "atlantis_aws_role_arn" {
  type    = string
  default = "arn:aws:iam::447542674857:role/iac_atlantis_admin"
}

# Environment settings
variable "aws_account_id" {
  type    = string
  default = "447542674857"
}

variable "env" {
  type    = string
  default = "dev"
}
