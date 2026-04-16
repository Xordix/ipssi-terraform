# =============================================================================
# modules/compute/main.tf
# ROLE 3 (Compute Engineer) — donnees partagees : AMI + cert TLS self-signed.
# =============================================================================
# OBJECTIF : le frontal applicatif complet — ALB + ASG + EC2 Nextcloud en Docker.
#
# Fichiers de ce module (chacun a completer) :
#   - alb.tf   : ALB + target group + 2 listeners (443 forward, 80 redirect)
#   - asg.tf   : launch template + auto scaling group
#   - templates/nextcloud-user-data.sh.tftpl : script user_data
#
# Ce fichier main.tf contient :
#   - resource "tls_private_key" "cert"              -> cle privee RSA 4096
#   - resource "tls_self_signed_cert" "cert"         -> cert auto-signe
#   - resource "aws_acm_certificate" "cert"          -> import du cert dans ACM
# =============================================================================

resource "tls_private_key" "self_signed" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "alb" {
  private_key_pem = tls_private_key.self_signed.private_key_pem

  subject {
    common_name  = "${local.name_prefix}.kolab.local"
    organization = "Kolab Cabinet Avocats"
  }

  validity_period_hours = 17520 # 2 ans

  # Usages autorises par le cert
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  # DNS alternatif : on autorise n importe quel domaine ALB AWS
  # (le DNS name de l ALB sera genere apres)
  dns_names = [
    "${local.name_prefix}.kolab.local",
    "*.elb.amazonaws.com",
    "*.eu-west-3.elb.amazonaws.com",
  ]
}

resource "aws_acm_certificate" "self_signed" {
  private_key      = tls_private_key.self_signed.private_key_pem
  certificate_body = tls_self_signed_cert.alb.cert_pem

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_region" "current" {}
