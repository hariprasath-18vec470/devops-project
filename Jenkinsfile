pipeline {
    agent any

    environment {
        APP_NAME = 'devops-webapp'
        BUILD_TAG = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Pulling latest code...'
                checkout scm
            }
        }

        stage('Validate') {
            steps {
                echo 'Validating files...'
                sh '''
                    test -f Dockerfile    && echo "Dockerfile found"    || exit 1
                    test -f app/index.html && echo "index.html found"   || exit 1
                    echo "Validation Passed!"
                '''
            }
        }

        stage('Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${APP_NAME}:${BUILD_TAG} ."
                sh "docker tag ${APP_NAME}:${BUILD_TAG} ${APP_NAME}:latest"
                echo 'Build complete!'
            }
        }

        stage('Deploy to DEV') {
            steps {
                echo 'Deploying to DEV environment...'
                sh '''
                    docker stop devops-webapp-dev 2>/dev/null || true
                    docker rm  devops-webapp-dev 2>/dev/null || true
                    docker run -d \
                        --name devops-webapp-dev \
                        -p 3001:80 \
                        devops-webapp:latest
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-dev)
                    echo "DEV Status: $STATUS"
                    [ "$STATUS" = "running" ] && echo "DEV Deploy Success!" || exit 1
                '''
            }
        }

        stage('Test DEV') {
            steps {
                echo 'Testing DEV environment...'
                sh '''
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-dev)
                    if [ "$STATUS" = "running" ]; then
                        echo "DEV Tests Passed!"
                    else
                        echo "DEV Tests Failed!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Deploy to STAGING') {
            steps {
                echo 'Deploying to STAGING environment...'
                sh '''
                    docker stop devops-webapp-staging 2>/dev/null || true
                    docker rm  devops-webapp-staging 2>/dev/null || true
                    docker run -d \
                        --name devops-webapp-staging \
                        -p 3002:80 \
                        devops-webapp:latest
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-staging)
                    echo "STAGING Status: $STATUS"
                    [ "$STATUS" = "running" ] && echo "STAGING Deploy Success!" || exit 1
                '''
            }
        }

        stage('Test STAGING') {
            steps {
                echo 'Testing STAGING environment...'
                sh '''
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-staging)
                    if [ "$STATUS" = "running" ]; then
                        echo "STAGING Tests Passed!"
                    else
                        echo "STAGING Tests Failed!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Approval for PROD') {
            steps {
                echo 'Waiting for Production Approval...'
                timeout(time: 2, unit: 'MINUTES') {
                    input message: 'Deploy to Production?',
                          ok: 'Yes, Deploy to PROD!'
                }
            }
        }

        stage('Deploy to PROD') {
            steps {
                echo 'Deploying to PRODUCTION...'
                sh '''
                    docker stop devops-webapp 2>/dev/null || true
                    docker rm  devops-webapp 2>/dev/null || true
                    docker run -d \
                        --name devops-webapp \
                        -p 3000:80 \
                        --restart unless-stopped \
                        devops-webapp:latest
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp)
                    echo "PROD Status: $STATUS"
                    [ "$STATUS" = "running" ] && echo "PROD Deploy Success!" || exit 1
                '''
            }
        }

        stage('Verify PROD') {
            steps {
                echo 'Verifying Production...'
                sh '''
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp)
                    if [ "$STATUS" = "running" ]; then
                        echo "Production is LIVE!"
                        echo "URL: http://localhost:3000"
                    else
                        echo "Production Verification Failed!"
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
            MULTI-STAGE PIPELINE SUCCESS!
            DEV     : http://localhost:3001
            STAGING : http://localhost:3002
            PROD    : http://localhost:3000
            ============================================
            '''
        }
        failure {
            echo 'PIPELINE FAILED! Check logs above.'
        }
        always {
            echo "Build #${BUILD_NUMBER} complete!"
        }
    }
}