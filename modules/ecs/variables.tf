variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "app_image_tag" {
  type = string
}

variable "ecs_cpu" {
  type = number
}

variable "ecs_memory" {
  type = number
}

variable "ecs_desired_count" {
  type = number
}

variable "django_settings_module" {
  type = string
}

variable "django_wsgi_module" {
  type = string
}

variable "celery_app" {
  type = string
}

variable "db_name" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "app_secret_arn" {
  type = string
}

variable "ecs_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "http_listener_arn" {
  type = string
}

