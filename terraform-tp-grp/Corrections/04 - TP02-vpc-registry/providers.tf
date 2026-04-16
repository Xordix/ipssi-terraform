# -----------------------------------------------------------------------------
# providers.tf
# Meme configuration que le TP02 custom.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "formation-terraform"
      Module      = "tp02-vpc-registry"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
