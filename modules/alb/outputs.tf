output "target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

