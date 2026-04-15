# outputs.tf
output "bucket_name" {
  value       = aws_s3_bucket.s3_bucket.id
  description = "Nom du bucket S3"
}

output "bucket_arn" {
  value       = aws_s3_bucket.s3_bucket.arn
  description = "ARN complet du bucket"
}

output "bucket_region" {
  value       = aws_s3_bucket.s3_bucket.region
  description = "Region AWS du bucket"
}

output "versioning_status" {
  value       = aws_s3_bucket_versioning.main.versioning_configuration[0].status
  description = "Statut du versioning"
}

output "aws_region" {
  value       = data.aws_region.current.name
  description = "region aws"
}

data "aws_region" "current" {}
