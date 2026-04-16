# -----------------------------------------------------------------------------
# variables.tf
# Memes variables que le TP02 custom pour permettre une comparaison 1:1.
# -----------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "Region AWS"
  default     = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "Environnement"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "project_name" {
  type        = string
  description = "Prefixe des ressources"
  default     = "formation"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR du VPC"
  default     = "10.1.0.0/16" # NB : different de tp02-vpc-complet pour
  # eviter toute collision si les deux sont apply en meme temps.
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr doit etre un CIDR valide."
  }
}

variable "azs" {
  type        = list(string)
  description = "Liste des AZ"
  default     = ["eu-west-1a", "eu-west-1b"]
}
