# -----------------------------------------------------------------------------
# outputs.tf
# -----------------------------------------------------------------------------

output "bucket_name" {
  value       = aws_s3_bucket.main.id
  description = "Nom du bucket S3"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "ARN complet du bucket"
}

output "region" {
  value       = local.region
  description = "Region AWS utilisee (lue via data source)"
}

output "account_id" {
  value       = local.account_id
  description = "ID du compte AWS (lu via data source)"
}

output "name_prefix" {
  value       = local.name_prefix
  description = "Prefixe normalise des ressources"
}

output "tags_applied" {
  value       = aws_s3_bucket.main.tags_all
  description = "Tous les tags effectivement appliques au bucket (default_tags + tags ressource)"
}
