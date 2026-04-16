# -----------------------------------------------------------------------------
# main.tf
# VPC custom complet : VPC + 2 subnets publics + 2 subnets prives + IGW
# + NAT Gateway single + route tables + security group bastion SSH.
#
# Total : 17 ressources.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # indispensable pour les services manages (RDS...)

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway : sortie internet des subnets publics
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# -----------------------------------------------------------------------------
# Subnets publics (1 par AZ)
# for_each sur la map AZ->CIDR calculee dans locals.tf.
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true # IP publique auto sur les EC2 dans ce subnet

  tags = {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  }
}

# -----------------------------------------------------------------------------
# Subnets prives (1 par AZ)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-private-${each.key}"
    Tier = "private"
  }
}

# -----------------------------------------------------------------------------
# Elastic IP pour le NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }

  # Le NAT ne fonctionne que si l'IGW est deja attache au VPC.
  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# NAT Gateway (single, dans la 1ere AZ pour economie ~35 EUR/mois)
# En prod : utiliser 1 NAT par AZ pour la HA (doublement du cout).
# -----------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id

  # IMPORTANT : le NAT doit etre dans un subnet PUBLIC (il a besoin d'acces
  # internet via l'IGW pour pouvoir faire le NAT). var.azs[0] = premiere AZ.
  subnet_id = aws_subnet.public[var.azs[0]].id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Route table publique : 0.0.0.0/0 -> IGW
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

# -----------------------------------------------------------------------------
# Route table privee : 0.0.0.0/0 -> NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

# -----------------------------------------------------------------------------
# Association route table publique <-> subnets publics
# Sans cette association, les subnets utilisent la "main route table" par
# defaut (sans route vers IGW) et n'ont donc pas internet.
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Association route table privee <-> subnets prives
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------------------------------------------------------
# Security Group : bastion SSH
# A utiliser au TP03 pour les instances bastion qui acceptent SSH depuis
# une IP autorisee.
# -----------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Allow SSH to bastion from authorized IP"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-bastion-sg"
  }
}

# Regle d'ingress : SSH (port 22) depuis l'IP autorisee.
# Depuis provider AWS v5, on utilise aws_vpc_security_group_ingress_rule
# (ressources separees), pas les blocs ingress {} dans aws_security_group.
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id

  description = "SSH depuis IP autorisee"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.bastion_allowed_cidr
}

# Regle d'egress : tout autoriser vers 0.0.0.0/0.
resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id

  description = "Egress all"
  ip_protocol = "-1" # tous protocoles
  cidr_ipv4   = "0.0.0.0/0"
}
