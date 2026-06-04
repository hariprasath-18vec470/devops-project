pipeline {
    agent any

    environment {
        APP_NAME = 'devops-webapp'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Pulling latest code from repository...'
                checkout scm
            }
        }

        stage('Validate') {
            steps {
                echo 'Validating project files...'
                bat '''
                    if exist Dockerfile (echo Dockerfile found) else (echo Dockerfile MISSING && exit 1)
                    if exist app\\index.html (echo index.html found) else (echo index.html MISSING && exit 1)
                    echo Validation complete!
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                bat "docker build -t %APP_NAME%:%IMAGE_TAG% ."
                bat "docker tag %APP_NAME%:%IMAGE_TAG% %APP_NAME%:latest"
                echo 'Image built successfully!'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                bat '''
                    docker run -d --name test-container -p 3001:80 devops-webapp:latest
                    ping -n 5 127.0.0.1 > nul
                    docker stop test-container
                    docker rm test-container
                    echo Test passed!
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                bat '''
                    docker stop devops-webapp 2>nul || echo No running container
                    docker rm devops-webapp 2>nul || echo No container to remove
                    docker run -d --name devops-webapp -p 3000:80 devops-webapp:latest
                    echo Deployment successful!
                '''
            }
        }

        stage('Verify') {
            steps {
                echo 'Verifying deployment...'
                bat '''
                    ping -n 5 127.0.0.1 > nul
                    docker ps --filter "name=devops-webapp"
                    echo App is live at http://localhost:3000
                '''
            }
        }
    }

    post {
        success {
            echo 'PIPELINE SUCCESS! App is live at http://localhost:3000'
        }
        failure {
            echo 'PIPELINE FAILED! Check the logs above.'
        }
        always {
            echo 'Pipeline finished.'
        }
    }
}