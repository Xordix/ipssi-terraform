# -----------------------------------------------------------------------------
# main.tf
# Bucket S3 securise production-ready :
#   - Nom unique (account_id + random_pet)
#   - Versioning active
#   - Chiffrement SSE-S3 (AES256)
#   - Block Public Access (4 options a true)
#   - Bucket Policy qui refuse toute requete non-HTTPS
#   - Tags normalises
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Contexte AWS et randomisation du nom
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "random_pet" "suffix" {
  length    = 2
  separator = "-"
}

# Locals : valeurs derivees reutilisees plusieurs fois.
locals {
  # Les noms S3 sont globalement uniques. On suffixe avec l'ID de compte
  # et un random_pet pour garantir l'unicite sans collision.
  bucket_name = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${random_pet.suffix.id}"
}

# -----------------------------------------------------------------------------
# Bucket S3 principal
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  # force_destroy = false (defaut) : terraform destroy echoue si des objets
  # sont presents. En prod, on laisse false pour eviter les destructions
  # accidentelles. Pour la formation, on peut passer a true si besoin.
  force_destroy = false

  tags = {
    # Ces tags viennent s'ajouter aux default_tags definis dans providers.tf.
    Owner = var.owner
    Name  = local.bucket_name
  }
}

# -----------------------------------------------------------------------------
# Versioning active
# -----------------------------------------------------------------------------
# Avec le versioning, chaque modification/suppression d'objet cree une version
# plutot que d'ecraser. Protection de base contre la suppression accidentelle.
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# Chiffrement cote serveur (SSE-S3 / AES256)
# -----------------------------------------------------------------------------
# SSE-S3 : AWS gere les cles (invisibles). Gratuit, simple.
# En production, preferez SSE-KMS avec une CMK pour pouvoir auditer/rotater.
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# Block Public Access : 4 controles activees
# -----------------------------------------------------------------------------
# Empeche techniquement toute exposition publique du bucket. A ne desactiver
# QUE dans des cas tres specifiques (site statique public), et explicitement.
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Bucket Policy : refuser toute requete non-HTTPS
# -----------------------------------------------------------------------------
# aws_iam_policy_document : construit le JSON de la policy en syntaxe HCL.
# Plus lisible et validable que du JSON litteral.
data "aws_iam_policy_document" "force_tls" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    # On cible le bucket lui-meme ET tous ses objets.
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]

    # Condition : si aws:SecureTransport est false, on refuse.
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.force_tls.json

  # IMPORTANT : la bucket policy doit etre appliquee APRES le public access
  # block, sinon AWS refuse la policy en pensant qu'elle pourrait autoriser
  # du public (meme si elle ne fait que refuser).
  depends_on = [aws_s3_bucket_public_access_block.main]
}
