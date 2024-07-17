terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Atlantis: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#assuming-an-iam-role-using-a-web-identity
provider "aws" {
  region = var.aws_region 

  # Local auth
  #profile = var.aws_profile_name 

  # Atlantis auth in k8s
  #assume_role_with_web_identity {
  #  role_arn                = var.atlantis_aws_role_arn
  #  session_name            = "${var.env}-atlantis-session"
  #  web_identity_token_file = ""
  #}
 default_tags {
   tags = {
     Environment = "DEV"
     Project     = "Atlantis"
   }
 }
}
