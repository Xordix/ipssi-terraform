# =============================================================================
# modules/security/iam.tf
# IAM role + instance profile pour les EC2 Nextcloud.
# Policies scopees : Secrets Manager + KMS Decrypt.
# (La policy S3 scope sur le bucket primary est declaree dans envs/dev/main.tf
#  pour eviter la dependance circulaire entre data et security.)
# =============================================================================
# Ressources a declarer :
#
#   - aws_iam_role             "app"   (assume_role_policy pour ec2.amazonaws.com)
#   - aws_iam_role_policy      "app_secrets"  (Allow secretsmanager:GetSecretValue
#                                              sur les 2 secrets ARN)
#   - aws_iam_role_policy      "app_kms"      (Allow kms:Decrypt + kms:DescribeKey
#                                              sur var.kms_key_arn — celle de ce module)
#   - aws_iam_role_policy_attachment "app_ssm"        (bonus, pour SSM Session Manager)
#   - aws_iam_role_policy_attachment "app_cloudwatch" (bonus, pour CW Agent)
#   - aws_iam_instance_profile "app"   (role = aws_iam_role.app.name)
#
# Pattern assume_role_policy :
#   data "aws_iam_policy_document" "assume_ec2" {
#     statement {
#       actions = ["sts:AssumeRole"]
#       principals {
#         type        = "Service"
#         identifiers = ["ec2.amazonaws.com"]
#       }
#     }
#   }
#
# Pattern policy inline :
#   resource "aws_iam_role_policy" "app_secrets" {
#     name = "..."
#     role = aws_iam_role.app.id
#     policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [{
#         Effect   = "Allow"
#         Action   = ["secretsmanager:GetSecretValue"]
#         Resource = [aws_secretsmanager_secret.db_password.arn,
#                     aws_secretsmanager_secret.admin_password.arn]
#       }]
#     })
#   }
# =============================================================================

# TODO(role-5) : aws_iam_role "app" avec assume_role_policy ec2.amazonaws.com

# TODO(role-5) : aws_iam_role_policy "app_secrets" (scope = les 2 secrets ARN)

# TODO(role-5) : aws_iam_role_policy "app_kms" (scope = aws_kms_key.main.arn)

# TODO(role-5) : 2 aws_iam_role_policy_attachment (SSM + CloudWatch) — bonus

# TODO(role-5) : aws_iam_instance_profile "app"

data "aws_iam_policy_document" "app_assume_role" {
  statement {
    sid     = "AssumeEC2Service"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"] # L'EC2 est le seul service autorisé à prendre ce rôle
    }
  }
}

#############################################
# 2. Le Rôle IAM principal (The Role)
#############################################

resource "aws_iam_role" "app" {
  name               = "${local.name_prefix}-app"
  description        = "Rôle runtime pour l'instance Nextcloud EC2, limité aux actions métier."
  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json # Utilisation de la politique d'assumation

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-role"
  })
}


#############################################
# 3a. Policy Secrets Manager : Accès aux secrets (Scope Secret ARN)
#############################################
data "aws_iam_policy_document" "app_secrets" {
  statement {
    sid    = "NextcloudSecretsRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue", # Action de lecture du secret
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.db_password.arn,   # SCOPE : ARN spécifique 1
      aws_secretsmanager_secret.admin_password.arn # SCOPE : ARN spécifique 2
    ]
  }
}

resource "aws_iam_role_policy" "app_secrets" {
  name   = "${local.name_prefix}-app-secrets"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_secrets.json
}

#############################################
# 3b. Policy KMS : Droit de déchiffrement (Scope CMK ARN)
#############################################
data "aws_iam_policy_document" "app_kms" {
  statement {
    sid    = "NextcloudKmsDecryptAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey" # Nécessaire pour valider l'existence de la clé
    ]
    resources = [
      aws_kms_key.main.arn # SCOPE : L'ARN unique de la CMK
    ]
  }
}

resource "aws_iam_role_policy" "app_kms" {
  name   = "${local.name_prefix}-app-kms"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_kms.json
}


#############################################
# 4. Attachments de Policies AWS Managées (Bonus)
#############################################

# SSM Session Manager : Permet la connexion à distance sans SSH Key Pair, un standard DevSecOps.
resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name # Attache le rôle au service de politique
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent : Permet la centralisation des métriques et logs AWS (Monitoring).
resource "aws_iam_role_policy_attachment" "app_cloudwatch" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#############################################
# 5. Instance Profile : Le lien final avec l'EC2
#############################################

resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app-profile"
  role = aws_iam_role.app.name # L'InstanceProfile est le conteneur du rôle pour les EC2.

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-profile"
  })
}
