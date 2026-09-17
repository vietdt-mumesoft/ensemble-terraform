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

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly two AZs for this Phase 1 architecture"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
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

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "ensemble"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "ensemble_admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GiB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS autoscaling upper limit in GiB"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable RDS Multi-AZ"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "Existing ACM certificate ARN for api domain. Leave empty to expose HTTP only."
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

variable "enable_nat_gateway_per_az" {
  description = "Create one NAT Gateway per AZ. More resilient but more expensive."
  type        = bool
  default     = false
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
