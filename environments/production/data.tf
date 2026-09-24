data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = [var.existing_vpc_name]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  tags = {
    Name = var.existing_public_subnet_tag_pattern
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  tags = {
    Name = var.existing_private_subnet_tag_pattern
  }
}

data "aws_security_group" "existing_alb" {
  filter {
    name   = "group-name"
    values = [var.existing_alb_sg_name]
  }
  vpc_id = data.aws_vpc.existing.id
}

data "aws_security_group" "existing_rds" {
  filter {
    name   = "group-name"
    values = [var.existing_rds_sg_name]
  }
  vpc_id = data.aws_vpc.existing.id
}
