output "alb_sg_id" {
  value = local.alb_sg_id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs.id
}


