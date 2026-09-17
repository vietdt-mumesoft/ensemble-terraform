# Ensemble AWS Infrastructure - Terraform

This stack provisions the Phase 1.0 architecture:

- VPC `10.0.0.0/16`
- 2 public subnets
- 2 private application subnets
- 2 private database subnets
- Internet Gateway
- NAT Gateway (1 by default; optional 1 per AZ)
- ALB
- ECS Fargate
  - Django/Gunicorn
  - Celery Worker
  - Redis sidecar
- RDS MySQL 8.0
- ECR
- CloudWatch Logs
- IAM roles
- RDS-managed master password in Secrets Manager
- Optional GitHub Actions OIDC deployment role
- Optional ACM HTTPS listener

## Important architecture note

Redis is a sidecar in the same ECS task because the requested diagram is a single ECS service.

Therefore keep:

```text
ecs_desired_count = 1
```

until Redis is moved to a shared service such as ElastiCache. With multiple ECS tasks, each task would have its own Redis sidecar.

## Prerequisites

Install:

- Terraform >= 1.8
- AWS CLI
- Docker
- An AWS identity with permission to create the resources

Configure AWS credentials through an AWS profile or environment variables. Do not put AWS access keys in Terraform files.

## 1. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`.

## 2. Initialize

```bash
terraform init
```

## 3. Validate

```bash
terraform fmt -recursive
terraform validate
```

## 4. Create ECR first

The ECS service expects an image to exist.

```bash
terraform apply -target=aws_ecr_repository.api
```

Get the repository URL:

```bash
terraform output -raw ecr_repository_url
```

## 5. Build and push your Docker image

Example:

```bash
AWS_REGION=ap-northeast-1
ECR_URL=$(terraform output -raw ecr_repository_url)

aws ecr get-login-password --region "$AWS_REGION"   | docker login --username AWS --password-stdin "$ECR_URL"

docker build -t ensemble-api:latest .
docker tag ensemble-api:latest "$ECR_URL:latest"
docker push "$ECR_URL:latest"
```

## 6. Create the rest of the infrastructure

```bash
terraform plan
terraform apply
```

## 7. Check ALB

```bash
terraform output -raw alb_dns_name
```

Then test:

```text
http://<ALB_DNS_NAME>/health/
```

Your Django application must provide:

```text
GET /health/
```

and return HTTP 200.



## 8. Application secret

Terraform creates the Secrets Manager container:

```text
ensemble/production/app
```

It does not create the secret value.

Before starting ECS tasks, populate it:

```bash
aws secretsmanager put-secret-value \
  --secret-id "ensemble/production/app" \
  --secret-string '{
    "DJANGO_SECRET_KEY":"REPLACE_ME",
    "STRIPE_API_KEY":"REPLACE_ME",
    "STRIPE_WEBHOOK_SECRET":"REPLACE_ME",
    "KEYSTONE_API_BASE_URL":"https://your-keystone-host",
    "KEYSTONE_CLIENT_ID":"REPLACE_ME",
    "KEYSTONE_CLIENT_SECRET":"REPLACE_ME"
  }'
```

Do not put the real values into `terraform.tfvars` or Git.

## 9. RDS credentials

RDS is configured with:

```text
manage_master_user_password = true
```

AWS manages the master password in Secrets Manager. Terraform does not define a plaintext database password.

The ECS execution role is granted access to the RDS-managed secret, and the Django/Celery containers receive:

```text
DB_HOST
DB_USER
DB_PASSWORD
```

from that secret.

## 10. GitHub Actions

If `github_repository` is set, Terraform creates an OIDC provider and deployment role restricted to the configured branch.

The workflow can then use:

```yaml
permissions:
  id-token: write
  contents: read
```

and:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}
    aws-region: ap-northeast-1
```

Do not store long-lived AWS access keys in GitHub Actions.

## 11. HTTPS

Create/verify an ACM certificate separately and put its ARN into:

```hcl
certificate_arn = "arn:aws:acm:..."
```

Then:

```bash
terraform apply
```

HTTP will redirect to HTTPS.

## 12. Stripe / Keystone / SES

Terraform creates the AWS infrastructure, but it does not automatically configure:

- Stripe webhook endpoint
- Stripe products/payment links
- Keystone application itself
- external Keystone credentials
- SES email content
- Django database migrations
- Django application secrets such as Stripe webhook secret

Those application-level settings should be added to Secrets Manager and referenced by the ECS task definition.

## 13. Destroy

Do not casually run:

```bash
terraform destroy
```

on production. RDS has deletion protection enabled and contains application data.
