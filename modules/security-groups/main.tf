resource "aws_security_group" "alb" {
  count = var.alb_sg_id == "" ? 1 : 0

  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "ALB public ingress"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.certificate_arn != "" ? [1] : []

    content {
      description = "HTTPS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

locals {
  alb_sg_id = var.alb_sg_id != "" ? var.alb_sg_id : aws_security_group.alb[0].id
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "ECS task security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Django from ALB"
    protocol        = "tcp"
    from_port       = 8000
    to_port         = 8000
    security_groups = [local.alb_sg_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}

