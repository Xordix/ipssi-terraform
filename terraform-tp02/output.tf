# outputs.tf
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "vpc_id"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "vpc_cidr"
}

output "public_subnet_ids" {
  value       = local.public_subnets
  description = "public_subnets"
}

output "private_subnet_ids" {
  value       = local.private_subnets
  description = "private_subnets"
}

output "nat_gateway_public_ip" {
  value       = aws_eip.nat.public_ip
  description = "IP publique du NAT Gateway"
}

output "bastion_security_group_id" {
  value       = aws_security_group.bastion.id
  description = "ID du Security Group bastion (a utiliser au TP03)"
}
