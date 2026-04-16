# -----------------------------------------------------------------------------
# locals.tf
# Calculs intermediaires : prefixe de nom + CIDR de subnets calcules
# dynamiquement avec cidrsubnet().
# -----------------------------------------------------------------------------

locals {
  # Prefixe normalise pour toutes les ressources du VPC.
  name_prefix = "${var.project_name}-${var.environment}"

  # Map AZ -> CIDR des subnets publics.
  # cidrsubnet("10.0.0.0/16", 8, 1) = 10.0.1.0/24
  # cidrsubnet("10.0.0.0/16", 8, 2) = 10.0.2.0/24
  public_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 1)
  }

  # Map AZ -> CIDR des subnets prives (offset +100 pour eviter les collisions
  # avec les subnets publics).
  # cidrsubnet("10.0.0.0/16", 8, 101) = 10.0.101.0/24
  private_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 101)
  }
}
