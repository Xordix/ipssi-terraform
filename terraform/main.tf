# Recuperer l ID du compte AWS courant
data "aws_caller_identity" "current" {}

# Generer un suffixe aleatoire pour eviter les collisions de nom
resource "random_pet" "bucket_suffix" {
  length    = 2
  separator = "-"
}

locals {
  bucket_name = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${random_pet.bucket_suffix.id}"
}

# Le bucket S3
resource "aws_s3_bucket" "s3_bucket" {
  bucket = local.bucket_name

  tags = {
    Owner = var.owner
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rule" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "force_tls" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.force_tls.json

  # Important : la policy doit etre appliquee apres le public access block,
  # sinon AWS refuse "block_public_policy"
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}
