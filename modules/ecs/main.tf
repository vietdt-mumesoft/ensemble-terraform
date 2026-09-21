resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

locals {
  api_image = "${var.ecr_repository_url}:${var.app_image_tag}"

  django_environment = [
    {
      name  = "APP_ENV"
      value = "staging"
    },
    {
      name  = "TIME_ZONE"
      value = "Asia/Tokyo"
    },
    {
      name  = "DEBUG"
      value = "False"
    },
    {
      name  = "DB_ENGINE"
      value = "django.db.backends.mysql"
    },
    {
      name  = "DB_PORT"
      value = "3306"
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
        { name = "DB_HOST", valueFrom = "${var.app_secret_arn}:DB_HOST::" },
        { name = "DB_USER", valueFrom = "${var.app_secret_arn}:DB_USER::" },
        { name = "DB_PASSWORD", valueFrom = "${var.app_secret_arn}:DB_PASSWORD::" },
        { name = "DB_NAME", valueFrom = "${var.app_secret_arn}:DB_NAME::" },
        { name = "DJANGO_SECRET_KEY", valueFrom = "${var.app_secret_arn}:DJANGO_SECRET_KEY::" },
        { name = "REDIS_HOST", valueFrom = "${var.app_secret_arn}:REDIS_HOST::" },
        { name = "REDIS_PORT", valueFrom = "${var.app_secret_arn}:REDIS_PORT::" },
        { name = "REDIS_DB", valueFrom = "${var.app_secret_arn}:REDIS_DB::" },
        { name = "REDIS_URL", valueFrom = "${var.app_secret_arn}:REDIS_URL::" },
        { name = "CELERY_BROKER_URL", valueFrom = "${var.app_secret_arn}:CELERY_BROKER_URL::" },
        { name = "CELERY_RESULT_BACKEND", valueFrom = "${var.app_secret_arn}:CELERY_RESULT_BACKEND::" },
        { name = "API_PREFIX", valueFrom = "${var.app_secret_arn}:API_PREFIX::" },
        { name = "EMAIL_BACKEND", valueFrom = "${var.app_secret_arn}:EMAIL_BACKEND::" },
        { name = "EMAIL_HOST", valueFrom = "${var.app_secret_arn}:EMAIL_HOST::" },
        { name = "EMAIL_PORT", valueFrom = "${var.app_secret_arn}:EMAIL_PORT::" },
        { name = "EMAIL_USE_TLS", valueFrom = "${var.app_secret_arn}:EMAIL_USE_TLS::" },
        { name = "EMAIL_USE_SSL", valueFrom = "${var.app_secret_arn}:EMAIL_USE_SSL::" },
        { name = "DEFAULT_FROM_EMAIL", valueFrom = "${var.app_secret_arn}:DEFAULT_FROM_EMAIL::" },
        { name = "EMAIL_HOST_USER", valueFrom = "${var.app_secret_arn}:EMAIL_HOST_USER::" },
        { name = "EMAIL_HOST_PASSWORD", valueFrom = "${var.app_secret_arn}:EMAIL_HOST_PASSWORD::" },
        { name = "STRIPE_API_KEY", valueFrom = "${var.app_secret_arn}:STRIPE_API_KEY::" },
        { name = "STRIPE_WEBHOOK_SECRET", valueFrom = "${var.app_secret_arn}:STRIPE_WEBHOOK_SECRET::" },
        { name = "KEYSTONE_API_BASE_URL", valueFrom = "${var.app_secret_arn}:KEYSTONE_API_BASE_URL::" },
        { name = "KEYSTONE_CLIENT_ID", valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_ID::" },
        { name = "KEYSTONE_CLIENT_SECRET", valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_SECRET::" }
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

      environment = local.django_environment

      secrets = [
        { name = "DB_HOST", valueFrom = "${var.app_secret_arn}:DB_HOST::" },
        { name = "DB_USER", valueFrom = "${var.app_secret_arn}:DB_USER::" },
        { name = "DB_PASSWORD", valueFrom = "${var.app_secret_arn}:DB_PASSWORD::" },
        { name = "DB_NAME", valueFrom = "${var.app_secret_arn}:DB_NAME::" },
        { name = "DJANGO_SECRET_KEY", valueFrom = "${var.app_secret_arn}:DJANGO_SECRET_KEY::" },
        { name = "REDIS_HOST", valueFrom = "${var.app_secret_arn}:REDIS_HOST::" },
        { name = "REDIS_PORT", valueFrom = "${var.app_secret_arn}:REDIS_PORT::" },
        { name = "REDIS_DB", valueFrom = "${var.app_secret_arn}:REDIS_DB::" },
        { name = "REDIS_URL", valueFrom = "${var.app_secret_arn}:REDIS_URL::" },
        { name = "CELERY_BROKER_URL", valueFrom = "${var.app_secret_arn}:CELERY_BROKER_URL::" },
        { name = "CELERY_RESULT_BACKEND", valueFrom = "${var.app_secret_arn}:CELERY_RESULT_BACKEND::" },
        { name = "API_PREFIX", valueFrom = "${var.app_secret_arn}:API_PREFIX::" },
        { name = "EMAIL_BACKEND", valueFrom = "${var.app_secret_arn}:EMAIL_BACKEND::" },
        { name = "EMAIL_HOST", valueFrom = "${var.app_secret_arn}:EMAIL_HOST::" },
        { name = "EMAIL_PORT", valueFrom = "${var.app_secret_arn}:EMAIL_PORT::" },
        { name = "EMAIL_USE_TLS", valueFrom = "${var.app_secret_arn}:EMAIL_USE_TLS::" },
        { name = "EMAIL_USE_SSL", valueFrom = "${var.app_secret_arn}:EMAIL_USE_SSL::" },
        { name = "DEFAULT_FROM_EMAIL", valueFrom = "${var.app_secret_arn}:DEFAULT_FROM_EMAIL::" },
        { name = "EMAIL_HOST_USER", valueFrom = "${var.app_secret_arn}:EMAIL_HOST_USER::" },
        { name = "EMAIL_HOST_PASSWORD", valueFrom = "${var.app_secret_arn}:EMAIL_HOST_PASSWORD::" },
        { name = "STRIPE_API_KEY", valueFrom = "${var.app_secret_arn}:STRIPE_API_KEY::" },
        { name = "STRIPE_WEBHOOK_SECRET", valueFrom = "${var.app_secret_arn}:STRIPE_WEBHOOK_SECRET::" },
        { name = "KEYSTONE_API_BASE_URL", valueFrom = "${var.app_secret_arn}:KEYSTONE_API_BASE_URL::" },
        { name = "KEYSTONE_CLIENT_ID", valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_ID::" },
        { name = "KEYSTONE_CLIENT_SECRET", valueFrom = "${var.app_secret_arn}:KEYSTONE_CLIENT_SECRET::" }
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
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-${var.environment}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.ecs_desired_count

  launch_type = "FARGATE"

  deployment_minimum_healthy_percent = var.environment == "production" ? 50 : 0
  deployment_maximum_percent         = var.environment == "production" ? 200 : 100
  availability_zone_rebalancing      = "DISABLED"

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


