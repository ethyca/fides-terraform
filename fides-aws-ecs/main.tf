terraform {
  required_version = "~> 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.97.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Needed for CloudFront certificates (must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "main" {}
