variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "owner" {
  type        = string
  description = "Email de l owner du bucket (utilise pour le tag Owner)"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.owner))
    error_message = "owner doit etre un email valide."
  }
}

variable "aws_region" {
  type        = string
  description = "region utilisé"

  default = "eu-west-3"
}

variable "project_name" {
  type        = string
  description = "nom du projet"

  default = "formation"
}

variable "vpc_cidr" {
  type        = string
  description = "nom du projet"

  default = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Format du CIDR pas valide"
  }
}

variable "azs" {
  type        = list(string)
  description = "liste des AZ"

  default = ["eu-west-3a", "eu-west-3b"]
}

variable "bastion_allowed_cidr" {
  type        = string
  description = "CIDR autorise a se connecter en SSH au bastion"

  default = "0.0.0.0/0"
}

