# -----------------------------------------------------------------------------
# variables.tf
# Variables typees avec validation. Illustre les types et mecanismes
# principaux du Module 07.
# -----------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "Region AWS de deploiement"
  default     = "eu-west-1"
}

variable "project" {
  type        = string
  description = "Nom du projet (sert de prefixe aux ressources)"
  default     = "formation-terraform"
}

variable "environment" {
  type        = string
  description = "Environnement (dev, staging, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "owner" {
  type        = string
  description = "Email du proprietaire (obligatoire, valide par regex)"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner))
    error_message = "owner doit etre une adresse email valide."
  }
}

# Type map(string) : dictionnaire de tags additionnels fournis par l'utilisateur.
# Ces tags sont merges avec les default_tags au niveau provider.
variable "tags" {
  type        = map(string)
  description = "Tags additionnels a appliquer a toutes les ressources"
  default = {
    CostCenter = "formation"
  }
}
