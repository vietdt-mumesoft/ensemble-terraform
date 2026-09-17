resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

locals {
  db_secret_arn = var.db_secret_arn
  api_image     = "${var.ecr_repository_url}:${var.app_image_tag}"

  django_environment = [
    {
      name  = "DJANGO_SETTINGS_MODULE"
      value = var.django_settings_module
    },
    {
      name  = "DB_NAME"
      value = var.db_name
    },
    {
      name  = "DB_PORT"
      value = "3306"
    },
    {
      name  = "REDIS_URL"
      value = "redis://127.0.0.1:6379/0"
    },
    {
      name  = "AWS_REGION_NAME"
      value = var.aws_region
    }
  ]
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.ecs_cpu
  memory = var.ecs_memory

  execution_role_arn = var.ecs_execution_role_arn
  task_role_arn      = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "django"
      image     = local.api_image
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = local.django_environment

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${local.db_secret_arn}:host::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${local.db_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${local.db_secret_arn}:password::"
        },
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = "${var.app_secret_arn}:DJANGO_SECRET_KEY::"
        },
        {
          name      = "STRIPE_API_KEY"
          valueFrom = "${var.app_secret_arn}:STRIPE_API_KEY::"
        },
        {
          name      = "STRIPE_WEBHOOK_SECRET"
          valueFrom = "${var.app_secret_arn}:STRIPE_WEBHOOK_SECRET::"
        },
        {
          name      = "KEYSTONE_API_BASE_URL"
          valueFrom = "${var.app_secret_arn}:KEYSTONE_API_BASE_URL::"
        },
        {
          name      = "KEYSTONE_CLIENT_ID"
          valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_ID::"
        },
        {
          name      = "KEYSTONE_CLIENT_SECRET"
          valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_SECRET::"
        }
      ]

      command = [
        "gunicorn",
        "${var.django_wsgi_module}:application",
        "--bind",
        "0.0.0.0:8000",
        "--workers",
        "3"
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/')\" || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.django.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "django"
        }
      }
    },
    {
      name      = "celery"
      image     = local.api_image
      essential = true

      environment = concat(local.django_environment, [
        {
          name  = "CELERY_BROKER_URL"
          value = "redis://127.0.0.1:6379/0"
        }
      ])

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${local.db_secret_arn}:host::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${local.db_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${local.db_secret_arn}:password::"
        },
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = "${var.app_secret_arn}:DJANGO_SECRET_KEY::"
        },
        {
          name      = "STRIPE_API_KEY"
          valueFrom = "${var.app_secret_arn}:STRIPE_API_KEY::"
        },
        {
          name      = "STRIPE_WEBHOOK_SECRET"
          valueFrom = "${var.app_secret_arn}:STRIPE_WEBHOOK_SECRET::"
        },
        {
          name      = "KEYSTONE_API_BASE_URL"
          valueFrom = "${var.app_secret_arn}:KEYSTONE_API_BASE_URL::"
        },
        {
          name      = "KEYSTONE_CLIENT_ID"
          valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_ID::"
        },
        {
          name      = "KEYSTONE_CLIENT_SECRET"
          valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_SECRET::"
        }
      ]

      command = [
        "celery",
        "-A",
        var.celery_app,
        "worker",
        "-l",
        "info"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.celery.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "celery"
        }
      }
    },
    {
      name      = "redis"
      image     = "redis:7-alpine"
      essential = true

      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "redis"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-${var.environment}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.ecs_desired_count

  launch_type = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "django"
    container_port   = 8000
  }

  depends_on = [
        var.http_listener_arn
  ]
}

resource "aws_cloudwatch_log_group" "django" {
  name              = "/ecs/${var.project_name}/${var.environment}/django"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "celery" {
  name              = "/ecs/${var.project_name}/${var.environment}/celery"
  retention_in_days = 30

}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/${var.project_name}/${var.environment}/redis"
  retention_in_days = 7
}
