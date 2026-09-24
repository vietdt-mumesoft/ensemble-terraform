variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "alb_sg_id" {
  description = "Existing ALB security group id to allow ECS ingress from. When empty, a new ALB security group is created in this module."
  type        = string
  default     = ""
}

