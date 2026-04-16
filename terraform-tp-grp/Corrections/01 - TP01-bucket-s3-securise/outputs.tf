# -----------------------------------------------------------------------------
# outputs.tf
# Valeurs affichees apres apply. Exposees via 'terraform output'.
# -----------------------------------------------------------------------------

output "bucket_name" {
  value       = aws_s3_bucket.main.id
  description = "Nom (id) du bucket S3"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "ARN complet du bucket S3"
}

output "bucket_region" {
  value       = aws_s3_bucket.main.region
  description = "Region AWS du bucket"
}

output "versioning_status" {
  value       = aws_s3_bucket_versioning.main.versioning_configuration[0].status
  description = "Statut du versioning (attendu : Enabled)"
}

# Note : aws_s3_bucket_server_side_encryption_configuration.main.rule est un set,
# pas une liste. On utilise one([for ...]) pour extraire l'algorithme de
# chiffrement du seul rule defini.
output "encryption_algorithm" {
  value = one([
    for r in aws_s3_bucket_server_side_encryption_configuration.main.rule :
    one([for s in r.apply_server_side_encryption_by_default : s.sse_algorithm])
  ])
  description = "Algorithme de chiffrement par defaut (attendu : AES256)"
}
