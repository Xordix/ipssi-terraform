# -----------------------------------------------------------------------------
# main.tf
# Reprise du TP01 (bucket S3) parametre via variables + locals + data sources.
# Objectif pedagogique : montrer variable vs local vs data source sur un cas
# concret.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Data sources : lectures externes sans effet de bord
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Locals : calculs intermediaires reutilises
# -----------------------------------------------------------------------------
locals {
  # Prefixe normalise applique a toutes les ressources.
  name_prefix = "${var.project}-${var.environment}"

  # Suffixe construit avec le compte et la region pour eviter les collisions.
  # On sort les donnees de data sources ici pour eviter les interpolations
  # redondantes dans main.tf.
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# -----------------------------------------------------------------------------
# Suffixe aleatoire
# -----------------------------------------------------------------------------
resource "random_pet" "suffix" {
  length    = 2
  separator = "-"
}

# -----------------------------------------------------------------------------
# Bucket S3 parametre
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket = "${local.name_prefix}-${local.account_id}-${random_pet.suffix.id}"

  # On ajoute le tag Owner au niveau ressource (les autres tags viennent
  # des default_tags au niveau provider).
  #   tags = {
  #     Owner = var.owner
  #     Name  = "${local.name_prefix}-bucket"
  #   }
  # }
  tags = merge(
    var.tags,
    {
      Owner = var.owner
      Name  = "${local.name_prefix}-bucket"
    }
  )
}

# -----------------------------------------------------------------------------
# Block Public Access (securite minimale)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
