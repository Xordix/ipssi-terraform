variable "vpc_id" {
  type        = string
  description = "ID du VPC (output du module networking)"
}

variable "private_db_subnet_ids" {
  type        = map(string)
  description = "Map AZ -> subnet_id prive DB (2 subnets sur 2 AZ pour Multi-AZ)"
}

variable "db_security_group_id" {
  type        = string
  description = "SG attache au RDS (fourni par le module security)"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN de la CMK KMS (fournie par le module security)"
}

variable "db_password_secret_arn" {
  type        = string
  description = "ARN du secret Secrets Manager contenant le mot de passe DB"
}

variable "project_name" {
  type    = string
  default = "kolab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type        = number
  default     = 100
  description = "Autoscaling storage (gp3) pour absorber les uploads Nextcloud"
}

variable "db_engine_version" {
  type    = string
  default = "16.4"
}
