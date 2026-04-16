# =============================================================================
# modules/compute/alb.tf
# Application Load Balancer + target group + 2 listeners.
# =============================================================================
# Ressources a declarer :
#
#   - aws_lb "main"
#       - internal            = false
#       - load_balancer_type  = "application"
#       - security_groups     = [var.alb_security_group_id]
#       - subnets             = values(var.public_subnet_ids)
#       - drop_invalid_header_fields = true   (securite)
#       - enable_http2        = true
#       - access_logs {
#           bucket  = var.s3_logs_bucket_name
#           prefix  = "alb"
#           enabled = true
#         }
#
#   - aws_lb_target_group "nextcloud"
#       - name_prefix        = "nc-"              (utiliser name_prefix, pas name,
#                                                  pour compatibilite create_before_destroy)
#       - port               = 80                 (HTTP en interne, HTTPS se termine a l ALB)
#       - protocol           = "HTTP"
#       - vpc_id             = var.vpc_id
#       - target_type        = "instance"
#       - health_check {
#           path                = "/status.php"
#           matcher             = "200-399"
#           interval            = 30
#           timeout             = 10
#           healthy_threshold   = 2
#           unhealthy_threshold = 5
#           protocol            = "HTTP"
#         }
#       - lifecycle { create_before_destroy = true }
#
#   - aws_lb_listener "https"
#       - port              = 443
#       - protocol          = "HTTPS"
#       - certificate_arn   = aws_acm_certificate.cert.arn
#       - ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#       - default_action { type = "forward" ; target_group_arn = aws_lb_target_group.nextcloud.arn }
#
#   - aws_lb_listener "http_redirect"
#       - port     = 80
#       - protocol = "HTTP"
#       - default_action {
#           type = "redirect"
#           redirect {
#             port        = "443"
#             protocol    = "HTTPS"
#             status_code = "HTTP_301"
#           }
#         }
# =============================================================================

# TODO(role-3) : aws_lb

resource "aws_lb" "main" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = values(var.public_subnet_ids)

  drop_invalid_header_fields = true(securite)
  enable_deletion_protection = false

  enable_http2 = true
  access_logs {
    bucket  = var.s3_logs_bucket_name
    prefix  = "alb"
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}
# TODO(role-3) : aws_lb_target_group

resource "aws_lb_target_group" "nextcloud" {
  name_prefix = "nc-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # Deregistration delay : temps avant retrait d une EC2 degradee
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/status.php"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tg"
  })

  # create_before_destroy : evite une fenetre sans TG si on renomme
  lifecycle {
    create_before_destroy = true
  }
}

# TODO(role-3) : aws_lb_listener "https" (default_action = forward target_group)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.self_signed.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = local.common_tags
}
# TODO(role-3) : aws_lb_listener "http_redirect" (default_action = redirect to 443)

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}
