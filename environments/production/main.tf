module "security-groups" {
  source          = "../../modules/security-groups"
  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = data.aws_vpc.existing.id
  certificate_arn = var.certificate_arn
  alb_sg_id       = data.aws_security_group.existing_alb.id
}

module "alb" {
  source                     = "../../modules/alb"
  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = data.aws_vpc.existing.id
  public_subnet_ids          = data.aws_subnets.public.ids
  alb_sg_id                  = data.aws_security_group.existing_alb.id
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = var.enable_deletion_protection
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}

module "secrets" {
  source       = "../../modules/secrets"
  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source            = "../../modules/iam"
  project_name      = var.project_name
  environment       = var.environment
  github_repository = var.github_repository
  github_branch     = var.github_branch
  app_secret_arn    = module.secrets.app_secret_arn
}

module "ecs" {
  source                 = "../../modules/ecs"
  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  app_image_tag          = var.app_image_tag
  ecs_cpu                = var.ecs_cpu
  ecs_memory             = var.ecs_memory
  ecs_desired_count      = var.ecs_desired_count
  django_settings_module = var.django_settings_module
  django_wsgi_module     = var.django_wsgi_module
  celery_app             = var.celery_app
  ecr_repository_url     = module.ecr.repository_url
  app_secret_arn         = module.secrets.app_secret_arn
  ecs_execution_role_arn = module.iam.ecs_execution_role_arn
  ecs_task_role_arn      = module.iam.ecs_task_role_arn
  app_subnet_ids         = data.aws_subnets.private.ids
  ecs_sg_id              = module.security-groups.ecs_sg_id
  target_group_arn       = module.alb.target_group_arn
  http_listener_arn      = module.alb.http_listener_arn
}

# Allow the ensemble ECS tasks to reach the shared, pre-existing RDS (MySQL) instance.
# Standalone rule so we don't take over management of the existing security group.
resource "aws_security_group_rule" "rds_from_ecs" {
  type                     = "ingress"
  security_group_id        = data.aws_security_group.existing_rds.id
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = module.security-groups.ecs_sg_id
  description              = "${var.project_name}-${var.environment} ECS tasks"
}
