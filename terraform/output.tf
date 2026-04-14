# outputs.tf
output "bucket_name" {
  value       = aws_s3_bucket.first.id
  description = "Nom du bucket S3 cree"
}

output "bucket_arn" {
  value       = aws_s3_bucket.first.arn
  description = "ARN complet du bucket"
}

output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "ID du compte AWS"
}
