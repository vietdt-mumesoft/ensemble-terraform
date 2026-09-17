output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.app_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.vpc.db_subnet_ids
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "rds_secret_arn" {
  value     = module.rds.db_secret_arn
  sensitive = true
}

output "github_actions_role_arn" {
  value = module.iam.github_actions_role_arn
}
