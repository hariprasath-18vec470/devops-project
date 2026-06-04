pipeline {
    agent any

    environment {
        APP_NAME = 'devops-webapp'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('📥 Checkout') {
            steps {
                echo '🔄 Pulling latest code from repository...'
                checkout scm
            }
        }

        stage('🔍 Validate') {
            steps {
                echo '🔍 Validating project files...'
                sh '''
                    echo "Checking required files..."
                    test -f Dockerfile && echo "✅ Dockerfile found"
                    test -f app/index.html && echo "✅ index.html found"
                    test -f deploy.sh && echo "✅ deploy.sh found"
                    echo "Validation complete!"
                '''
            }
        }

        stage('🏗️ Build Docker Image') {
            steps {
                echo '🏗️ Building Docker image...'
                sh "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:latest"
                echo "✅ Image built: ${APP_NAME}:${IMAGE_TAG}"
            }
        }

        stage('🧪 Test') {
            steps {
                echo '🧪 Running tests...'
                sh '''
                    # Start a test container
                    docker run -d --name test-container -p 3001:80 devops-webapp:latest

                    # Wait for it to start
                    sleep 3

                    # Check if container is running
                    STATUS=$(docker inspect --format='{{.State.Status}}' test-container)
                    echo "Container Status: $STATUS"

                    # Check HTTP response
                    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001)
                    echo "HTTP Response Code: $HTTP_CODE"

                    # Cleanup test container
                    docker stop test-container
                    docker rm test-container

                    # Validate response
                    if [ "$HTTP_CODE" = "200" ]; then
                        echo "✅ Test Passed! App returned HTTP 200"
                    else
                        echo "❌ Test Failed! Expected 200, got $HTTP_CODE"
                        exit 1
                    fi
                '''
            }
        }

        stage('🚀 Deploy') {
            steps {
                echo '🚀 Deploying application...'
                sh 'chmod +x deploy.sh && ./deploy.sh'
            }
        }

        stage('✅ Verify') {
            steps {
                echo '✅ Verifying deployment...'
                sh '''
                    sleep 2
                    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
                    if [ "$HTTP_CODE" = "200" ]; then
                        echo "✅ Deployment verified! App is live at http://localhost:3000"
                    else
                        echo "❌ Verification failed!"
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
            ✅ PIPELINE SUCCESS!
            🌐 App: http://localhost:3000
            ============================================
            '''
        }
        failure {
            echo '''
            ============================================
            ❌ PIPELINE FAILED! Check logs above.
            ============================================
            '''
        }
        always {
            echo "🧹 Pipeline finished. Build #${BUILD_NUMBER}"
        }
    }
}