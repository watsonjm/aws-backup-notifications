terraform {
  required_version = "~> 1.2.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.17.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = local.common_tags }
}