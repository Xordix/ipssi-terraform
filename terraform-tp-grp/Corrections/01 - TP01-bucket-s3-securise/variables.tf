# -----------------------------------------------------------------------------
# variables.tf
# Toutes les entrees parametrables du projet. Typage strict et validation
# pour detecter les erreurs le plus tot possible (avant meme le plan).
# -----------------------------------------------------------------------------

variable "bucket_prefix" {
  type        = string
  description = "Prefixe applique au nom du bucket S3"
  default     = "formation-tp01"
}

variable "environment" {
  type        = string
  description = "Environnement de deploiement (dev/staging/prod)"
  default     = "dev"

  # Validation : refus immediat si la valeur n'est pas dans la liste.
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "owner" {
  type        = string
  description = "Email de l'owner du bucket (utilise pour le tag Owner)"

  # Validation regex : format email simple.
  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner))
    error_message = "owner doit etre une adresse email valide."
  }
}

variable "aws_region" {
  type        = string
  description = "Region AWS de deploiement"
  default     = "eu-west-1"
}
