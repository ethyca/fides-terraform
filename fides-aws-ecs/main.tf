terraform {
  required_version = "~> 1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47"
    }
  }
}
provider "aws" {
  region = var.aws_region
}

data "aws_region" "current" {}
