# DevOps Challenge – Production-Ready Application Deployment

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Logging](#monitoring--logging)
- [Design Decisions](#design-decisions)
- [Assumptions](#assumptions)
- [Limitations & Improvements](#limitations--improvements)

---

## Architecture Overview

```
                        ┌──────────────┐
                        │    GitHub     │
                        └──────┬───────┘
                               │ webhook / poll
                        ┌──────▼───────┐
                        │   Jenkins    │  EC2 (public subnet 1)
                        │   CI/CD      │  IAM role → ECR + ECS access
                        └──────┬───────┘
                               │ docker push
                        ┌──────▼───────┐
                        │     ECR      │  Container registry
                        └──────┬───────┘
                               │ image pull
┌──────────────────────────────▼──────────────────────────────┐
│                      VPC  (10.0.0.0/16)                     │
│                                                             │
│   ┌───────────────────┐       ┌───────────────────┐         │
│   │  Public Subnet 1  │       │  Public Subnet 2  │         │
│   │   10.0.1.0/24     │       │   10.0.2.0/24     │         │
│   │   (AZ-a)          │       │   (AZ-b)          │         │
│   └───────┬───────────┘       └───────┬───────────┘         │
│           │       ┌───────────────────┘                     │
│           │       │                                         │
│       ┌───▼───────▼───┐                                    │
│       │  ALB (port 80) │  Internet-facing                   │
│       └───┬───────┬───┘                                    │
│           │       │                                         │
│     ┌─────▼──┐ ┌──▼─────┐                                  │
│     │Fargate │ │Fargate │   ECS Service (port 8080)         │
│     │Task    │ │Task    │   .NET 9 API                      │
│     └────────┘ └────────┘                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                               │
                        ┌──────▼───────┐
                        │  CloudWatch  │  Logs + Container Insights
                        └──────────────┘
```

**Traffic flow:** User → ALB (port 80) → ECS Fargate tasks (port 8080) → .NET API

---

## Project Structure

```
ChallengeApp/
├── Program.cs                 
├── ChallengeApp.csproj        
├── Dockerfile                 
├── Jenkinsfile                
├── README.md
├── terraform/
│   ├── main.tf                
│   ├── variables.tf           
│   ├── outputs.tf             
│   ├── providers.tf           
│   ├── backend.tf             
│   └── modules/
│       ├── networking/        
│       ├── security/          
│       ├── alb/    
│       ├── ecr/             
│       ├── ecs/               
│       └── jenkins/           
```

---

## Prerequisites

- **AWS Account** with programmatic access configured (`aws configure`)
- **Terraform** >= 1.5.0
- **Docker** installed locally (for testing)
- **AWS CLI** v2
- An **EC2 Key Pair** created in your target region (if SSH access to Jenkins is needed). If not, use EC2 Instance Connect to access the instance in the browser to retrieve the initial admin password.

---

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/faoziltomiwa-blip/ChallengeApp.git
cd ChallengeApp
```

### 2. Provision Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
```

After apply completes, note the outputs:
- `app_url` — the ALB URL to access the application
- `jenkins_url` — Jenkins dashboard URL
- `ecr_repository_url` — ECR repo for Docker images

> **Note on Initial State:** After Terraform provisioning, the ECS service will temporarily be in a "failing" state because the ECR repository is completely empty. Running the Jenkins pipeline for the first time will automatically build the image, push it to ECR, and force the ECS deployment to resolve this.

### 3. Configure Jenkins

1. Navigate to the Jenkins URL from terraform output
2. Retrieve the initial admin password:
   - Go to the AWS Console -> EC2 -> Instances
   - Select the `Jenkins-ci-server` instance and click **Connect**
   - Use **EC2 Instance Connect** to open a terminal in your browser
   - Run: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Install suggested plugins
4. Create a Pipeline job pointing to the repository's `Jenkinsfile`
5. Update the `ECR_REPO` environment variable in the Jenkinsfile with the ECR URL

### 4. Verify the Application

```bash
curl http://<alb-dns-name>/
# {"message":"API is running!","environment":"Production","timestamp":"..."}

curl http://<alb-dns-name>/health
# {"status":"Healthy"}
```

---

## CI/CD Pipeline

The Jenkins pipeline (`Jenkinsfile`) automates the full delivery lifecycle:

| Stage | Description |
|-------|-------------|
| **Checkout** | Pulls latest code from the Git repository |
| **Docker Build** | Builds the container image using the multi-stage Dockerfile (which safely handles the .NET compilation inside the container) |
| **Push to ECR** | Authenticates with ECR via IAM instance profile and pushes the image |
| **Deploy to ECS** | Forces a new ECS deployment to pull the latest image |

**Authentication:** Jenkins uses an IAM Instance Profile (no hardcoded AWS credentials). The attached IAM role grants permissions for ECR push and ECS service updates.

---

## Monitoring & Logging

- **CloudWatch Logs**: All ECS container stdout/stderr is streamed to CloudWatch Log Group `/ecs/devops-challenge` with 30-day retention
- **Container Insights**: Enabled on the ECS cluster for CPU, memory, and network metrics
- **Health Check**: ALB target group performs HTTP health checks on `/health` endpoint every 30 seconds
- **ECR Image Scanning**: Automatic vulnerability scanning on every image push

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Fargate over EC2 launch type** | Serverless compute eliminates EC2 fleet management. Right-sized for a lightweight API. |
| **Public subnets for ECS** | Simplifies architecture by avoiding NAT Gateway costs (~$32/month). Fargate tasks get public IPs with security group restricting inbound to ALB only. |
| **Modular Terraform** | Each concern (networking, security, ALB, ECR, ECS, Jenkins) is isolated for reusability and clarity. |
| **Multi-stage Dockerfile** | Build stage uses the full SDK, runtime stage uses the slim ASP.NET image (~220MB vs ~900MB). |
| **IAM Instance Profile for Jenkins** | Avoids storing AWS credentials. Jenkins authenticates via the EC2 metadata service. |
| **Health check on /health** | Dedicated health endpoint prevents ALB from routing traffic to unhealthy containers. |
| **Container port 8080** | ASP.NET default for non-root containers. Avoids running as root inside the container. |
| **S3 backend with DynamoDB** | Remote state is fully configured, enabling safe state locking and team collaboration. |

---

## Assumptions

- AWS credentials are configured locally for Terraform (`aws configure` or environment variables)
- The AMI `ami-0e294ce625e6437e2` is available in `eu-west-2` (Amazon Linux 2023)
- Jenkins plugins (Pipeline, Git, Docker) are installed during initial setup
- The application does not require a database or external services
- A single ECS task (desired_count=1) is sufficient for this demonstration

---

## Limitations & Improvements

| Current Limitation | Suggested Improvement |
|---|---|
| No HTTPS/TLS | Add ACM certificate + HTTPS listener on ALB |
| No auto-scaling | Add ECS Service Auto Scaling based on CPU/memory |
| No private subnets | Add private subnets + NAT Gateway for production workloads |
| Hardcoded AMI ID | Use `data "aws_ami"` to dynamically fetch the latest Amazon Linux |
| No secrets management | Use AWS Secrets Manager or SSM Parameter Store |
| No multi-environment support | Add Terraform workspaces or separate tfvars per environment |
| Basic health check | Implement readiness + liveness probes with detailed status |
| No DNS/domain | Add Route 53 hosted zone with a friendly domain name |
