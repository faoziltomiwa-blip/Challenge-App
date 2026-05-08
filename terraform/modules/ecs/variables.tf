variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}
