# -----------------------------------------------------------------------------
# providers.tf
# Version Terraform et provider AWS. default_tags derives des variables.
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

provider "aws" {
  region = var.aws_region

  # default_tags construits a partir des variables + tags fournis par l'user.
  # merge() permet de combiner deux maps : les valeurs de var.tags surchargent
  # celles des tags par defaut en cas de conflit de cle.
  default_tags {
    tags = merge(
      {
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "Terraform"
        Module      = "07-variables-outputs-data"
      },
      var.tags
    )
  }
}
