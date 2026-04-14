# Recuperer l ID du compte AWS courant
data "aws_caller_identity" "current" {}

# Generer un suffixe aleatoire pour eviter les collisions de nom
resource "random_pet" "bucket_suffix" {
  length    = 2
  separator = "-"
}

# Le bucket S3
resource "aws_s3_bucket" "first" {
  bucket = "formation-tf-${data.aws_caller_identity.current.account_id}-${random_pet.bucket_suffix.id}"

  tags = {
    Name = "Premier bucket Terraform"
  }
}
