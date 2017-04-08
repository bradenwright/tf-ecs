output "app_url" {
  value = "http://${aws_alb.ecs.dns_name}"
}

