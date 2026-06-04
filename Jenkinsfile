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
                sh '''
                    echo "Checking required files..."
                    if [ -f Dockerfile ]; then
                        echo "Dockerfile found"
                    else
                        echo "Dockerfile NOT found"
                        exit 1
                    fi
                    if [ -f app/index.html ]; then
                        echo "index.html found"
                    else
                        echo "index.html NOT found"
                        exit 1
                    fi
                    echo "Validation complete!"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:latest"
                echo "Image built successfully!"
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh '''
                    docker stop test-container 2>/dev/null || true
                    docker rm test-container 2>/dev/null || true

                    docker run -d --name test-container -p 3001:80 devops-webapp:latest

                    sleep 3

                    STATUS=$(docker inspect --format="{{.State.Status}}" test-container)
                    echo "Container Status: $STATUS"

                    docker stop test-container
                    docker rm test-container

                    if [ "$STATUS" = "running" ]; then
                        echo "Test Passed!"
                    else
                        echo "Test Failed!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                sh '''
                    docker stop devops-webapp 2>/dev/null || true
                    docker rm devops-webapp 2>/dev/null || true

                    docker run -d \
                        --name devops-webapp \
                        -p 3000:80 \
                        --restart unless-stopped \
                        devops-webapp:latest

                    sleep 2

                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp)
                    echo "Deployment Status: $STATUS"

                    if [ "$STATUS" = "running" ]; then
                        echo "Deployment Successful!"
                    else
                        echo "Deployment Failed!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Verify') {
            steps {
                echo 'Verifying deployment...'
                sh '''
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp)
                    if [ "$STATUS" = "running" ]; then
                        echo "Verification Passed! App is live!"
                    else
                        echo "Verification Failed!"
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo '''
            ============================================
            PIPELINE SUCCESS!
            App is live at http://localhost:3000
            ============================================
            '''
        }
        failure {
            echo '''
            ============================================
            PIPELINE FAILED! Check logs above.
            ============================================
            '''
        }
        always {
            echo "Pipeline finished. Build done!"
        }
    }
}