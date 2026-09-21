resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project_name}/${var.project_name}-api/${var.environment}"
  description             = "Application secrets for Ensemble ECS tasks"
  recovery_window_in_days = 7
}

# Intentionally no aws_secretsmanager_secret_version is defined here.
# Secret values should be written outside Terraform so plaintext values do not
# get committed to this repository or unnecessarily enter Terraform state.
