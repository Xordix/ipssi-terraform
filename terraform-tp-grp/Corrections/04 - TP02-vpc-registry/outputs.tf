# -----------------------------------------------------------------------------
# outputs.tf
# On expose les outputs du module sous des noms identiques a ceux du TP02
# custom pour faciliter la comparaison.
# -----------------------------------------------------------------------------

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID du VPC"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR du VPC"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "Liste des IDs de subnets publics (ordre des var.azs)"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "Liste des IDs de subnets prives (ordre des var.azs)"
}

output "nat_gateway_public_ips" {
  value       = module.vpc.nat_public_ips
  description = "Liste des IPs publiques NAT (1 ou N selon single_nat_gateway)"
}

output "internet_gateway_id" {
  value       = module.vpc.igw_id
  description = "ID de l'Internet Gateway"
}
