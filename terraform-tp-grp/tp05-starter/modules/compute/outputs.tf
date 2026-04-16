output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS public de l ALB"
}

output "alb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "Zone Route53 alias de l ALB"
}

output "asg_name" {
  value       = aws_autoscaling_group.app.name
  description = "Nom de l ASG applicatif"
}

output "nextcloud_url" {
  value       = "https://${aws_lb.main.dns_name}"
  description = "URL Nextcloud a ouvrir dans le navigateur"
}

output "launch_template_id" {
  value       = aws_launch_template.app.id
  description = "ID du Launch Template (utile pour debug ASG)"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "ARN du target group (utile pour attacher d autres services)"
}
