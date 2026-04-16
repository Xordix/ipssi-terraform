# =============================================================================
# RDS PostgreSQL Multi-AZ + DB subnet group + parameter group.
# =============================================================================

# ---------------------------------------------------------------
# Lecture du mot de passe DB depuis Secrets Manager
# ---------------------------------------------------------------
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

# ---------------------------------------------------------------
# DB Subnet Group (2 subnets privés DB)
# ---------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = values(var.private_db_subnet_ids)

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

# ---------------------------------------------------------------
# Parameter Group PostgreSQL 16
# ---------------------------------------------------------------
resource "aws_db_parameter_group" "postgres16" {
  name   = "${local.name_prefix}-pg16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name = "${local.name_prefix}-pg16"
  }
}

# ---------------------------------------------------------------
# Instance RDS PostgreSQL Multi-AZ
# ---------------------------------------------------------------
resource "aws_db_instance" "nextcloud" {
  identifier = "${local.name_prefix}-nextcloud-rds"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # Haute dispo
  multi_az                = true
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Upgrades
  auto_minor_version_upgrade = true
  apply_immediately          = false

  # Logs vers CloudWatch
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_arn

  # Destruction (dev only)
  deletion_protection      = false
  skip_final_snapshot      = true
  delete_automated_backups = true

  # Paramètres custom
  parameter_group_name = aws_db_parameter_group.postgres16.name

  # IAM auth (bonus sécurité)
  iam_database_authentication_enabled = true

  # Connexion DB
  db_name  = "nextcloud"
  username = "nextcloud"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nextcloud-rds"
  })

  lifecycle {
    ignore_changes = [password]
  }
}
