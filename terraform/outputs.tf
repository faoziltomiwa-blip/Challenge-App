output "app_url" {
  description = "URL to access the application via ALB"
  value       = "http://${module.alb.alb_dns_name}"
}

output "jenkins_url" {
  description = "URL to access Jenkins dashboard"
  value       = "http://${module.jenkins.jenkins_public_ip}:8080"
}

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images"
  value       = module.ecr.repository_url
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}
