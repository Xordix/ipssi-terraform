# =============================================================================
# modules/security/sg.tf
# 3 Security Groups : alb (public), app (prive), db (prive-DB).
# =============================================================================
# Ressources a declarer :
#
#   - aws_security_group "alb"   (nom alb-sg, vpc_id = var.vpc_id)
#   - aws_security_group "app"   (nom app-sg, vpc_id = var.vpc_id)
#   - aws_security_group "db"    (nom db-sg,  vpc_id = var.vpc_id)
#
#   - aws_vpc_security_group_ingress_rule "alb_https"  : 443 from 0.0.0.0/0
#   - aws_vpc_security_group_ingress_rule "alb_http"   : 80  from 0.0.0.0/0 (redirect)
#   - aws_vpc_security_group_egress_rule  "alb_all"    : -1  to   0.0.0.0/0
#
#   - aws_vpc_security_group_ingress_rule "app_from_alb" : 80 from SG alb
#                                                          (referenced_security_group_id)
#   - aws_vpc_security_group_egress_rule  "app_all"      : -1 to   0.0.0.0/0
#
#   - aws_vpc_security_group_ingress_rule "db_from_app"  : 5432 TCP from SG app
#                                                          (referenced_security_group_id)
#
# 🟡 Rappel syntaxe v5+ : depuis le provider AWS 5.x, on utilise des ressources
#   separees aws_vpc_security_group_ingress_rule / _egress_rule (et non plus les
#   blocs ingress {} / egress {} dans aws_security_group).
#
# Pattern inter-SG : pour autoriser "app" depuis "alb", on utilise :
#   referenced_security_group_id = aws_security_group.alb.id
#   (et PAS cidr_ipv4 — les 2 arguments sont exclusifs)
# =============================================================================

# TODO(role-5) : 3 aws_security_group

# TODO(role-5) : 3 ingress + 2 egress rules
# =============================================================================

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "SG pour le Load Balancer Application (ALB). Accepte 80/443 depuis Internet."
  vpc_id      = var.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

# INGRESS ALB : HTTPS de l'Internet (Port 443)
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS (443) from Internet to ALB."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# INGRESS ALB : HTTP de l'Internet (Port 80 - Redirection)
resource "aws_vpc_security_group_ingress_rule" "alb_http_redirect" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP (80) from Internet to ALB for redirection."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# EGRESS ALB : Autoriser le trafic sortant vers Internet (pour les requêtes externes)
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all egress from ALB to connect with external services."
  cidr_ipv4         = "0.0.0.0/0" # Attention : C'est nécessaire pour que l'ALB puisse atteindre ses cibles !
  ip_protocol       = "-1"        # -1 signifie tous les protocoles (ALL)
}

#############################################
# SG APP - Couche applicative (Web Servers / Containers)
#############################################

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app"
  description = "SG pour les serveurs d'applications (EC2/ECS). Ne doit accepter que le trafic de l'ALB."
  vpc_id      = var.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app"
  })
}

# INGRESS APP : HTTP depuis L'ALB UNIQUEMENT (Règle Inter-SG)
resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP access from the ALB SG only."
  # POINT CLÉ : Utilisation du ID de l'autre SG, pas d'IP CIDR !
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# EGRESS APP : Autoriser le trafic sortant (Mises à jour, Pull Docker, accès S3/Secrets)
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all egress for application updates and external services."
  cidr_ipv4         = "0.0.0.0/0" # Nécessaire pour les pulls Docker ou connexions externes
  ip_protocol       = "-1"
}

#############################################
# SG DB - Couche de Base de Données (RDS)
#############################################

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db"
  description = "SG pour la base de données PostgreSQL (RDS). Très restrictif."
  vpc_id      = var.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db"
  })
}

# INGRESS DB : PostgreSQL depuis SG App UNIQUEMENT (Règle Inter-SG)
resource "aws_vpc_security_group_ingress_rule" "db_pg_from_app" {
  security_group_id = aws_security_group.db.id
  description       = "PostgreSQL access restricted ONLY to the Application SG."
  # POINT CLÉ : Réfère au groupe d'application, pas à un CIDR.
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# EGRESS DB : Minimal Egress dans le VPC (Sécurité maximale)
resource "aws_vpc_security_group_egress_rule" "db_minimal" {
  security_group_id = aws_security_group.db.id
  description       = "Minimal egress required within the local VPC CIDR."
  cidr_ipv4         = var.vpc_cidr # On ne sort que dans le périmètre du VPC !
  ip_protocol       = "-1"
}
