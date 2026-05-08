pipeline {
    agent any

    environment {
        AWS_REGION       = 'eu-west-2'
        ECR_REPO         = '825555019555.dkr.ecr.eu-west-2.amazonaws.com/devops-challenge'
        ECS_CLUSTER      = 'devops-challenge-cluster'
        ECS_SERVICE      = 'devops-challenge-service'
        IMAGE_TAG        = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }


        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
                sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REPO}:latest"
            }
        }

        stage('Push to ECR') {
            steps {
                echo 'Logging into ECR and pushing image...'
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REPO}
                """
                sh "docker push ${ECR_REPO}:${IMAGE_TAG}"
                sh "docker push ${ECR_REPO}:latest"
            }
        }

        stage('Deploy to ECS') {
            steps {
                echo 'Forcing new ECS deployment...'
                sh """
                    aws ecs update-service \
                        --cluster ${ECS_CLUSTER} \
                        --service ${ECS_SERVICE} \
                        --force-new-deployment \
                        --region ${AWS_REGION}
                """
            }
        }
    }

    post {
        success {
            echo "Deployment successful! Build #${env.BUILD_NUMBER}"
        }
        failure {
            echo "Deployment failed at build #${env.BUILD_NUMBER}"
        }
    }
}
