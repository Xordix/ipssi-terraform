output "alb_security_group_id" {
  description = "Security Group ID pour l ALB (consomme par module compute)"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security Group ID pour les EC2 app (consomme par module compute)"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security Group ID pour RDS (consomme par module data)"
  value       = aws_security_group.db.id
}

output "kms_key_id" {
  description = "ID de la KMS CMK principale"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "ARN de la KMS CMK principale (consomme par module data)"
  value       = aws_kms_key.main.arn
}

output "app_instance_profile_name" {
  description = "Nom de l instance profile (consomme par launch template module compute)"
  value       = aws_iam_instance_profile.app.name
}

output "app_iam_role_name" {
  description = "Nom du role IAM de l app (consomme par les policies IAM hors module)"
  value       = aws_iam_role.app.name
}

output "app_iam_role_arn" {
  description = "ARN du role IAM de l app (utile pour debug)"
  value       = aws_iam_role.app.arn
}

output "db_password_secret_arn" {
  description = "ARN du secret db_password (consomme par module data + compute user_data)"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "admin_password_secret_arn" {
  description = "ARN du secret admin_password (consomme par module compute user_data)"
  value       = aws_secretsmanager_secret.admin_password.arn
}
