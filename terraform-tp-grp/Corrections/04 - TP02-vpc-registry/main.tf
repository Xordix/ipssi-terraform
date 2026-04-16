# -----------------------------------------------------------------------------
# main.tf
# Equivalent fonctionnel du TP02 custom en 25 lignes, via le module officiel
# terraform-aws-modules/vpc/aws.
#
# Le module cree lui-meme : VPC, IGW, subnets (public + private), NAT Gateway,
# route tables, associations, etc. ~15 ressources sous-jacentes.
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5" # Pinner la version en prod. ~> 5.5 = [5.5.0, 6.0.0[

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs = var.azs

  # CIDR de subnets calcules dynamiquement avec cidrsubnet().
  # Offset +1 pour publics (1, 2, ...), +101 pour prives (101, 102, ...).
  public_subnets  = [for idx, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, idx + 1)]
  private_subnets = [for idx, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, idx + 101)]

  enable_nat_gateway = true
  single_nat_gateway = true # economie : 1 seul NAT vs 1 par AZ

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags appliques uniquement sur les subnets publics / prives
  # (en plus des default_tags du provider).
  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }
}
