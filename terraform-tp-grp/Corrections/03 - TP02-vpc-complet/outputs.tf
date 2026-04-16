# -----------------------------------------------------------------------------
# outputs.tf
# -----------------------------------------------------------------------------

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID du VPC"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR du VPC"
}

# Map AZ -> ID de subnet : plus lisible qu'une liste quand on a plusieurs AZ.
output "public_subnet_ids" {
  value       = { for k, s in aws_subnet.public : k => s.id }
  description = "Map AZ -> ID de subnet public"
}

output "private_subnet_ids" {
  value       = { for k, s in aws_subnet.private : k => s.id }
  description = "Map AZ -> ID de subnet prive"
}

output "nat_gateway_public_ip" {
  value       = aws_eip.nat.public_ip
  description = "IP publique elastique du NAT Gateway"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "ID de l'Internet Gateway"
}

output "bastion_security_group_id" {
  value       = aws_security_group.bastion.id
  description = "ID du Security Group bastion (a utiliser au TP03)"
}
