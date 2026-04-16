# module networking
module "networking" {
  source = "../../modules/networking"

  project_name = "kolab"
  environment  = "dev"
  vpc_cidr     = "10.30.0.0/16"
  azs          = ["eu-west-3a", "eu-west-3b"]
}

# module security
module "security" {
  source             = "../../modules/security"
  project_name       = "kolab"
  environment        = "dev"
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = module.networking.vpc_cidr
  allowed_admin_cidr = var.allowed_admin_cidr
}

# module data
module "data" {
  source = "../../modules/data" # Il manquait la source !

  project_name           = "kolab"
  environment            = "dev"
  vpc_id                 = module.networking.vpc_id
  private_db_subnet_ids  = module.networking.private_db_subnet_ids
  db_security_group_id   = module.security.db_security_group_id
  kms_key_arn            = module.security.kms_key_arn
  db_password_secret_arn = module.security.db_password_secret_arn
}

# module compute
module "compute" {
  source = "../../modules/compute"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  alb_security_group_id     = module.security.alb_security_group_id
  app_security_group_id     = module.security.app_security_group_id
  app_instance_profile_name = module.security.app_instance_profile_name
  db_endpoint               = module.data.db_endpoint
  db_name                   = module.data.db_name
  db_username               = module.data.db_username
  db_password_secret_arn    = module.security.db_password_secret_arn
  admin_password_secret_arn = module.security.admin_password_secret_arn
  s3_primary_bucket_name    = module.data.s3_primary_bucket_name
  s3_logs_bucket_name       = module.data.s3_logs_bucket_name
}

# La ressource IAM hors module
resource "aws_iam_role_policy" "app_s3_scoped" {
  name = "kolab-dev-app-s3-scoped"
  role = module.security.app_iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion",
        "s3:AbortMultipartUpload"
      ]
      Resource = [
        module.data.s3_primary_bucket_arn,
        "${module.data.s3_primary_bucket_arn}/*"
      ]
      }, {
      Effect   = "Allow"
      Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
      Resource = module.data.s3_primary_bucket_arn
    }]
  })
}
