variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name used in resource names"
  type        = string
  default     = "ensemble"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "existing_vpc_name" {
  description = "Name tag of the pre-existing VPC to deploy into"
  type        = string
}

variable "existing_public_subnet_tag_pattern" {
  description = "Name tag pattern (glob) matching the existing VPC's public subnets, used for the ALB"
  type        = string
}

variable "existing_private_subnet_tag_pattern" {
  description = "Name tag pattern (glob) matching the existing VPC's private subnets, used for ECS tasks"
  type        = string
}

variable "existing_alb_sg_name" {
  description = "Name of the pre-existing security group to attach to the ALB"
  type        = string
}

variable "existing_rds_sg_name" {
  description = "Name of the pre-existing RDS security group to allow ECS ingress on"
  type        = string
}

variable "app_image_tag" {
  description = "ECR image tag used by ECS"
  type        = string
  default     = "latest"
}

variable "ecs_cpu" {
  description = "Task CPU units"
  type        = number
  default     = 1024
}

variable "ecs_memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 2048
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks. Keep at 1 while Redis is a sidecar."
  type        = number
  default     = 1
}

variable "certificate_arn" {
  description = "Existing ACM certificate ARN for the ALB HTTPS listener. Leave empty to expose HTTP only."
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository in owner/repo format. Empty disables GitHub OIDC resources."
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the deployment role"
  type        = string
  default     = "main"
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "django_settings_module" {
  description = "Python path to Django settings module"
  type        = string
  default     = "configs.settings"
}

variable "django_wsgi_module" {
  description = "Python path to Django WSGI module"
  type        = string
  default     = "configs.wsgi"
}

variable "celery_app" {
  description = "Celery application passed to celery -A"
  type        = string
  default     = "configs"
}
