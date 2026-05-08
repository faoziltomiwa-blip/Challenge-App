#!/bin/bash
sudo yum update -y
sudo yum install -y git

# Installation of Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Installation of Java (Required for Jenkins)
sudo yum install -y java-21-amazon-corretto

# Installation of Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/rpm-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key
sudo yum upgrade -y
sudo yum install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Adding Jenkins user to Docker group so pipelines can build images
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins