variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Name of the project for tagging"
  type        = string
  default     = "devops-challenge"
}
