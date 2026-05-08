output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins_server.id
}
