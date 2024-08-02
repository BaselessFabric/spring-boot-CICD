pipeline {
    agent any
    environment {
        ECR_REGISTRY = 'public.ecr.aws/t7e9v6m0'
        ECR_REPOSITORY = 'spring-boot-practice-buildanddeploylambda'
        AWS_REGION = 'us-east-1' // Use us-east-1 for public ECR operations
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
                    docker.withRegistry("https://${ECR_REGISTRY}", AWS_CREDENTIALS_ID) {
                        sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.BUILD_NUMBER}"
                    }
                }
            }
        }
        stage('Update App Runner') {
            steps {
                withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGION) {
                    sh """
                    aws apprunner update-service --service-arn arn:aws:apprunner:eu-west-2:211125415319:service/${APP_RUNNER_SERVICE_NAME} \
                    --source-configuration ImageRepository={ImageIdentifier=${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.BUILD_NUMBER},ImageConfiguration={Port=8080}}
                    """
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        failure {
            mail to: 'alexanderwalls92@gmail.com',
                 subject: "Build ${currentBuild.fullDisplayName} Failed",
                 body: "Something went wrong. Please check the Jenkins job: ${env.BUILD_URL}"
        }
        success {
            mail to: 'alexanderwalls92@gmail.com',
                 subject: "Build ${currentBuild.fullDisplayName} Succeeded",
                 body: "The build was successful. Check the details at: ${env.BUILD_URL}"
        }
    }
}
