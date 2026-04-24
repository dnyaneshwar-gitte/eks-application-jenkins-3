pipeline {
    agent any

    environment {
        IMAGE_NAME = 'dnyaneshwar535/simple-react-app'
        IMAGE_TAG  = "${BUILD_NUMBER}"

        DOCKER = 'C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe'
        KUBECTL = 'C:\\Users\\dnyan\\Downloads\\kubectl.exe'
        KUBECONFIG_FILE = 'C:\\jenkins\\kube\\config'

        AWS_DEFAULT_REGION = 'ap-south-1'
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Code Checkout') {
            steps {
                git branch: 'develop',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/dnyaneshwar-gitte/eks-application-jenkins-3.git'
            }
        }

        stage('Check Files') {
            steps {
                bat 'dir'
                bat 'dir k8s_manifest'
            }
        }

        stage('Docker Build') {
            steps {
                bat '"%DOCKER%" build -t %IMAGE_NAME%:%IMAGE_TAG% .'
            }
        }

        stage('Publish to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASS'
                )]) {
                    bat '"%DOCKER%" login -u %DOCKERHUB_USER% -p %DOCKERHUB_PASS%'
                    bat '"%DOCKER%" push %IMAGE_NAME%:%IMAGE_TAG%'
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    bat '''
                    "%KUBECTL%" --kubeconfig="%KUBECONFIG_FILE%" apply -f k8s_manifest\\namespace.yaml
                    "%KUBECTL%" --kubeconfig="%KUBECONFIG_FILE%" apply -f k8s_manifest\\deployment.yaml
                    "%KUBECTL%" --kubeconfig="%KUBECONFIG_FILE%" apply -f k8s_manifest\\service.yaml
                    "%KUBECTL%" --kubeconfig="%KUBECONFIG_FILE%" set image deployment/react-app react-app=%IMAGE_NAME%:%IMAGE_TAG% -n dev
                    "%KUBECTL%" --kubeconfig="%KUBECONFIG_FILE%" rollout status deployment/react-app -n dev
                    '''
                }
            }
        }

        stage('Send Email Notification') {
            steps {
                emailext(
                    subject: "Jenkins Build ${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                    body: """Build Status: ${currentBuild.currentResult}
Job Name: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Image Deployed: ${env.IMAGE_NAME}:${env.IMAGE_TAG}
Check console output for more details.""",
                    to: "dnyaneshwarg535@gmail.com"
                )
            }
        }
    }

    post {
        success {
            echo 'Application deployed successfully to EKS.'
        }
        failure {
            echo 'Application pipeline failed.'
        }
        always {
            bat '"%DOCKER%" image prune -f'
        }
    }
}