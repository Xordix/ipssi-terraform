# providers.tf
terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "eu-west-3"

  default_tags {
    tags = {
      Project     = "formation-terraform"
      Module      = "tp02-vpc"
      ManagedBy   = "Terraform"
      Environment = var.environment
      CostCenter  = "formation"
    }
  }
}
