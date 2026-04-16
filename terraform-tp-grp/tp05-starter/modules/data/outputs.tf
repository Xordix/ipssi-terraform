output "db_endpoint" {
  value       = aws_db_instance.nextcloud.address
  description = "Hostname RDS (sans le port)"
}

output "db_port" {
  value       = aws_db_instance.nextcloud.port
  description = "Port RDS PostgreSQL (5432)"
}

output "db_name" {
  value       = aws_db_instance.nextcloud.db_name
  description = "Nom de la base logique"
}

output "db_username" {
  value       = aws_db_instance.nextcloud.username
  description = "Utilisateur master PostgreSQL"
}

output "s3_primary_bucket_name" {
  value       = aws_s3_bucket.primary.bucket
  description = "Nom du bucket primary storage Nextcloud"
}

output "s3_primary_bucket_arn" {
  value       = aws_s3_bucket.primary.arn
  description = "ARN du bucket primary (consommé par le module security pour la policy IAM)"
}

output "s3_logs_bucket_name" {
  value       = aws_s3_bucket.logs.bucket
  description = "Nom du bucket access logs ALB"
}

output "s3_logs_bucket_arn" {
  value       = aws_s3_bucket.logs.arn
  description = "ARN du bucket logs ALB"
}
