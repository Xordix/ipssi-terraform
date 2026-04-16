# -----------------------------------------------------------------------------
# variables.tf
# -----------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "Region AWS de deploiement"
  default     = "eu-west-1"
}

variable "environment" {
  type        = string
  description = "Environnement de deploiement"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "project_name" {
  type        = string
  description = "Prefixe applique aux noms de ressources"
  default     = "formation"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR du VPC (doit etre un /16 ou equivalent)"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr doit etre un CIDR valide (ex: 10.0.0.0/16)."
  }
}

variable "azs" {
  type        = list(string)
  description = "Liste des AZ a utiliser (minimum 2 pour la HA)"
  default     = ["eu-west-1a", "eu-west-1b"]

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Au moins 2 AZ requises pour la HA."
  }
}

variable "bastion_allowed_cidr" {
  type        = string
  description = "CIDR autorise en SSH sur le bastion (jamais 0.0.0.0/0 en prod)"
  default     = "0.0.0.0/0"
}
