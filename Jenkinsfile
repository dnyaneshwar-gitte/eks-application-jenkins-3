pipeline {
    agent any

    environment {
        IMAGE_NAME = 'dnyaneshwar535/simple-react-app'
        IMAGE_TAG  = "${BUILD_NUMBER}"
        KUBECONFIG = 'C:\\jenkins\\kube\\config'
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
                    url: 'https://github.com/YOUR_USERNAME/simple-node-js-react-npm-app.git'
            }
        }

        stage('Docker Build') {
            steps {
                bat "docker build -t %IMAGE_NAME%:%IMAGE_TAG% ."
            }
        }

        stage('Publish to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASS'
                )]) {
                    bat 'docker login -u %DOCKERHUB_USER% -p %DOCKERHUB_PASS%'
                    bat 'docker push %IMAGE_NAME%:%IMAGE_TAG%'
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
                    kubectl --kubeconfig=%KUBECONFIG% apply -f k8s_manifest/namespace.yaml

                    powershell -Command "(Get-Content k8s_manifest\\deployment.yaml) -replace 'dnyaneshwar535/simple-react-app:latest', '%IMAGE_NAME%:%IMAGE_TAG%' | Set-Content k8s_manifest\\deployment.yaml"

                    kubectl --kubeconfig=%KUBECONFIG% apply -f k8s_manifest/deployment.yaml
                    kubectl --kubeconfig=%KUBECONFIG% apply -f k8s_manifest/service.yaml
                    kubectl --kubeconfig=%KUBECONFIG% rollout status deployment/react-app -n dev
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
Check console output for more details.""",
                    to: "YOUR_EMAIL_ID@gmail.com"
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
            bat 'docker image prune -f'
        }
    }
}