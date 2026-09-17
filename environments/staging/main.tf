module "vpc" {
  source = "../../modules/vpc"
  project_name = var.project_name
  environment = var.environment
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway_per_az = var.enable_nat_gateway_per_az
}

module "security-groups" {
  source = "../../modules/security-groups"
  project_name = var.project_name
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  certificate_arn = var.certificate_arn
}

module "alb" {
  source = "../../modules/alb"
  project_name = var.project_name
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id = module.security-groups.alb_sg_id
  certificate_arn = var.certificate_arn
  enable_deletion_protection = var.enable_deletion_protection
}

module "ecr" {
  source = "../../modules/ecr"
  project_name = var.project_name
  environment = var.environment
}

module "rds" {
  source = "../../modules/rds"
  project_name = var.project_name
  environment = var.environment
  db_name = var.db_name
  db_username = var.db_username
  db_instance_class = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_multi_az = var.db_multi_az
  db_subnet_ids = module.vpc.db_subnet_ids
  rds_sg_id = module.security-groups.rds_sg_id
}

module "secrets" {
  source = "../../modules/secrets"
  project_name = var.project_name
  environment = var.environment
}

module "iam" {
  source = "../../modules/iam"
  project_name = var.project_name
  environment = var.environment
  github_repository = var.github_repository
  github_branch = var.github_branch
  db_secret_arn = module.rds.db_secret_arn
  app_secret_arn = module.secrets.app_secret_arn
}

module "ecs" {
  source = "../../modules/ecs"
  project_name = var.project_name
  environment = var.environment
  aws_region = var.aws_region
  app_image_tag = var.app_image_tag
  ecs_cpu = var.ecs_cpu
  ecs_memory = var.ecs_memory
  ecs_desired_count = var.ecs_desired_count
  django_settings_module = var.django_settings_module
  django_wsgi_module = var.django_wsgi_module
  celery_app = var.celery_app
  db_name = var.db_name
  ecr_repository_url = module.ecr.repository_url
  db_secret_arn = module.rds.db_secret_arn
  app_secret_arn = module.secrets.app_secret_arn
  ecs_execution_role_arn = module.iam.ecs_execution_role_arn
  ecs_task_role_arn = module.iam.ecs_task_role_arn
  app_subnet_ids = module.vpc.app_subnet_ids
  ecs_sg_id = module.security-groups.ecs_sg_id
  target_group_arn = module.alb.target_group_arn
  http_listener_arn = module.alb.http_listener_arn
}

