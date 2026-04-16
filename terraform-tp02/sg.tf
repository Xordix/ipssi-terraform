resource "aws_security_group" "bastion" {
  vpc_id      = aws_vpc.main.id
  name        = "${local.name_prefix}-bastion-sg"
  description = "SSH bastion"

  tags = {
    Name  = "formation-dev-bastion-sg"
    Owner = "etudiant13"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.bastion.id

  cidr_ipv4   = var.bastion_allowed_cidr
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_trafic" {
  security_group_id = aws_security_group.bastion.id

  description = "Egress all"
  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
