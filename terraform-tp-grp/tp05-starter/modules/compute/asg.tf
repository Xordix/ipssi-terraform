# =============================================================================
# modules/compute/asg.tf
# Launch Template + Auto Scaling Group single-instance.
# =============================================================================
# Ressources a declarer :
#
#   - aws_launch_template "app"
#       - name_prefix            = "${local.name_prefix}-nc-"
#       - image_id               = data.aws_ami.al2023.id
#       - instance_type          = "t3.small"     (1 Go RAM mini pour Docker)
#       - iam_instance_profile {
#           name = var.app_instance_profile_name
#         }
#       - vpc_security_group_ids = [var.app_security_group_id]
#       - user_data              = base64encode(templatefile(
#           "${path.module}/templates/nextcloud-user-data.sh.tftpl", {
#             aws_region                = data.aws_region.current.name
#             db_endpoint               = var.db_endpoint
#             db_name                   = var.db_name
#             db_username               = var.db_username
#             db_password_secret_arn    = var.db_password_secret_arn
#             admin_password_secret_arn = var.admin_password_secret_arn
#             s3_bucket                 = var.s3_primary_bucket_name
#           }
#         ))
#       - metadata_options {
#           http_tokens                 = "required"  # IMDSv2 obligatoire
#           http_put_response_hop_limit = 2           # Docker a besoin de 2 hops
#         }
#       - block_device_mappings {
#           device_name = "/dev/xvda"
#           ebs {
#             volume_size = 20
#             volume_type = "gp3"
#             encrypted   = true
#           }
#         }
#       - tag_specifications {
#           resource_type = "instance"
#           tags = { Name = "${local.name_prefix}-nextcloud" }
#         }
#       - update_default_version = true
#
#   - aws_autoscaling_group "app"
#       - name_prefix        = "${local.name_prefix}-nc-"
#       - min_size            = 1
#       - max_size            = 2
#       - desired_capacity    = 1
#       - vpc_zone_identifier = values(var.private_app_subnet_ids)
#       - target_group_arns   = [aws_lb_target_group.nextcloud.arn]
#       - health_check_type   = "ELB"
#       - health_check_grace_period = 300
#       - launch_template {
#           id      = aws_launch_template.app.id
#           version = "$Latest"
#         }
#       - tag {
#           key                 = "Name"
#           value               = "${local.name_prefix}-nextcloud"
#           propagate_at_launch = true
#         }
#       (+ tags Environment, Project propages)
#
# 🟡 Rappel : data "aws_region" "current" {} doit etre declare dans main.tf pour
#   pouvoir l utiliser dans le templatefile.
# =============================================================================
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
# TODO(role-3) : aws_launch_template "app"
resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-nc-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  # IAM instance profile fourni par le Role 5 (permet AWS CLI sur l EC2)
  iam_instance_profile {
    name = var.app_instance_profile_name
  }

  # Security Group app : seul l ALB peut parler HTTP 80 a l EC2
  vpc_security_group_ids = [var.app_security_group_id]

  # IMDSv2 obligatoire (contre le SSRF et les vols de credentials)
  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2 # 2 pour que Docker container puisse acceder IMDS
    instance_metadata_tags      = "enabled"
  }

  # Root volume chiffre par KMS (defaut AWS)
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # user_data rendu par templatefile() avec les valeurs des autres modules
  user_data = base64encode(templatefile("${path.module}/templates/nextcloud-user-data.sh.tftpl", {
    db_endpoint               = var.db_endpoint
    db_name                   = var.db_name
    db_username               = var.db_username
    db_password_secret_arn    = var.db_password_secret_arn
    admin_password_secret_arn = var.admin_password_secret_arn
    s3_primary_bucket_name    = var.s3_primary_bucket_name
    alb_dns_name              = aws_lb.main.dns_name
    aws_region                = data.aws_region.current.name
  }))

  # Tags propages aux instances creees par l ASG
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-nextcloud"
      Role = "nextcloud-app"
    })
  }

  update_default_version = true

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-launch-template"
  })

  # Si on change l AMI ou le user_data, on veut un nouveau LT avant suppression
  lifecycle {
    create_before_destroy = true
  }
}
# TODO(role-3) : aws_autoscaling_group "app"

resource "aws_autoscaling_group" "app" {
  name_prefix = "${local.name_prefix}-nc-"

  # Subnets prives (les EC2 ne sont JAMAIS exposees directement)
  vpc_zone_identifier = values(var.private_app_subnet_ids)

  # Taille : 1 seule instance a la fois (file locking Nextcloud sans Redis)
  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  # Health check ELB : l ASG suit l avis du target group
  health_check_type         = "ELB"
  health_check_grace_period = 300 # 5 min pour que Nextcloud finisse de booter

  # Rattachement au Launch Template (toujours la derniere version)
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Rolling refresh si le LT change : on cycle les instances une par une
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  # Tags propages a chaque instance creee (separe du tag_specifications du LT
  # pour etre sur que Name est bien propage).
  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-nextcloud"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  # create_before_destroy pour zero-downtime si on renomme l ASG
  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Rattachement ASG <-> Target Group (ressource separee en v5+)
# -----------------------------------------------------------------------------
resource "aws_autoscaling_attachment" "app_tg" {
  autoscaling_group_name = aws_autoscaling_group.app.name
  lb_target_group_arn    = aws_lb_target_group.app.arn
}
