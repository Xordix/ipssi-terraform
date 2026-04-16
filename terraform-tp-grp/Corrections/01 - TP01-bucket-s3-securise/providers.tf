# -----------------------------------------------------------------------------
# providers.tf
# Declaration Terraform + providers AWS et random.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.7.0"

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

# -----------------------------------------------------------------------------
# Provider AWS
# default_tags : applique automatiquement sur toutes les ressources creees
# par ce provider. Surcharge possible au niveau ressource.
# -----------------------------------------------------------------------------
provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Project     = "formation-terraform"
      Module      = "tp01-s3-secure"
      ManagedBy   = "Terraform"
      Environment = var.environment
      CostCenter  = "formation"
    }
  }
}
