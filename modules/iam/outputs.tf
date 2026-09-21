output "ecs_execution_role_arn" {
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
}

output "ecs_task_role_arn" {
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
}

output "github_actions_role_arn" {
  value = try(aws_iam_role.github_actions[0].arn, null)
}

