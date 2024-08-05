# Spring Boot CICD with Jenkins and AWS

This project demonstrates a CI/CD pipeline for a Spring Boot application using Jenkins, Docker, and AWS services (ECR and App Runner). The pipeline is triggered by commits to the main branch and follows best practices for continuous integration and deployment.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Pipeline Stages](#pipeline-stages)
- [Jenkinsfile](#jenkinsfile)
- [Dockerfile](#dockerfile)
- [IAM Policies](#iam-policies)

## Project Overview

The main branch represents the Minimum Viable Product (MVP) and is the branch that is deployed. This project uses Jenkins to build a new Docker image of the Spring Boot application when a new commit is detected on the main branch. The new image is uploaded to Amazon ECR and then re-deployed to AWS App Runner.

## Architecture

1. **Source Control**: GitHub repository.
2. **CI/CD Tool**: Jenkins.
3. **Containerization**: Docker.
4. **Artifact Repository**: Amazon ECR (Elastic Container Registry).
5. **Deployment Service**: AWS App Runner.

## Technologies Used

- Spring Boot
- Jenkins
- Docker
- Amazon ECR
- AWS App Runner
- Maven

## Prerequisites

- An AWS account with permissions to create and manage ECR repositories and App Runner services.
- A Jenkins server that is set up and configured.
- Docker installed on the Jenkins server. Note that the Dockerfile for the Jenkins server presented below uses the host machine's Docker installation via a socket.
- A GitHub repository containing the Spring Boot application.

## Setup Instructions

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/BaselessFabric/spring-boot-CICD.git
   ```

2. **Configure Jenkins**:
   - Install the necessary plugins: AWS Credentials, Docker, GitHub Integration.
   - Create credentials in Jenkins for AWS and GitHub.
   - Set up a pipeline in Jenkins and link it to your GitHub repository.

3. **AWS Setup**:
   - Create an ECR repository.
   - Create an App Runner service.
   - Ensure your IAM user has the required permissions (see [IAM Policies](#iam-policies)).

4. **Add the Jenkinsfile and Dockerfile to Your Repository**:
   - Ensure the `Jenkinsfile` and `Dockerfile` are in the root directory of your project.

## Pipeline Stages

1. **Checkout**: Clones the GitHub repository.
2. **Build**: Uses Maven to build the Spring Boot application.
3. **Prepare Docker Image**: Builds a Docker image for the application.
4. **Push to ECR**: Pushes the Docker image to Amazon ECR.
5. **Update App Runner**: Updates the AWS App Runner service with the new image.

## Jenkinsfile

```groovy
pipeline {
    agent any
    environment {
        ECR_REGISTRY = 'public.ecr.aws/t7e9v6m0'
        ECR_REPOSITORY = 'spring-boot-practice-buildanddeploylambda'
        AWS_REGION = 'us-east-1'
        APP_RUNNER_REGION = 'eu-west-2'
        AWS_CREDENTIALS_ID = 'jenkins-ecr-apprunner-credentials'
        APP_RUNNER_SERVICE_NAME = 'spring-boot-practice-cicd'
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/BaselessFabric/spring-boot-CICD.git', branch: 'main'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Prepare Docker Image') {
            steps {
                script {
                    sh "cp target/*.jar app.jar"
                    sh "docker build -t ${ECR_REPOSITORY}:${env.BUILD_NUMBER} ."
                    sh "docker tag ${ECR_REPOSITORY}:${env.BUILD_NUMBER} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.BUILD_NUMBER}"
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGION) {
                        sh "aws ecr-public get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.BUILD_NUMBER}"
                    }
                }
            }
        }
        stage('Update App Runner') {
            steps {
                withAWS(credentials: AWS_CREDENTIALS_ID, region: APP_RUNNER_REGION) {
                    sh """
                    aws apprunner update-service --service-arn arn:aws:apprunner:${APP_RUNNER_REGION}:211125415319:service/${APP_RUNNER_SERVICE_NAME} \
                    --source-configuration ImageRepository={ImageRepositoryType=ECR_PUBLIC,ImageIdentifier=${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.BUILD_NUMBER},ImageConfiguration={Port=8080}}
                    """
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
```

## Dockerfile

While the Dockerfile in this repository is visible, it pertains to the instructions that the Jenkins server uses to build the application image, which is then uploaded to AWS Elastic Container Registry. The Dockerfile provided below, however, was used to create the image of the Jenkins server that handles the build process.

```Dockerfile
# Start with the Jenkins image that includes JDK 21
FROM jenkins/jenkins:lts-alpine-jdk21

# Switch to the root user to install additional packages
USER root

# Install Docker client and other necessary packages
RUN apk update && \
    apk add --no-cache ansible neovim maven docker-cli && \
    rm -rf /var/cache/apk/* /var/lib/apt/lists/*

# Create the docker group if it doesn't exist
RUN addgroup -S docker || true

# Add Jenkins user to the docker group
RUN addgroup jenkins docker

# Switch back to the Jenkins user
USER jenkins

# Optional: Verify the installations
RUN ansible --version && nvim --version && mvn --version && docker --version
```

## IAM Policies

Ensure the IAM user used by Jenkins has the following policies attached:

- `AmazonEC2ContainerRegistryPublicFullAccess`
- `AWSAppRunnerFullAccess`

You can create a custom policy if needed:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr-public:GetAuthorizationToken",
                "sts:GetServiceBearerToken",
                "ecr-public:BatchCheckLayerAvailability",
                "ecr-public:PutImage",
                "ecr-public:InitiateLayerUpload",
                "ecr-public:UploadLayerPart",
                "ecr-public:CompleteLayerUpload"
            ],
            "Resource": "*"
        }
    ]
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Spring Boot](https://spring.io/projects/spring-boot)
- [Jenkins](https://www.jenkins.io/)
- [Docker](https://www.docker.com/)
- [Amazon ECR](https://aws.amazon.com/ecr/)
- [AWS App Runner](https://aws.amazon.com/apprunner/)

Feel free to contribute to this project by submitting issues or pull requests.
