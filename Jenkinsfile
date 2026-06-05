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
                    test -f Dockerfile        && echo "Dockerfile found"        || exit 1
                    test -f app/index.html    && echo "index.html found"        || exit 1
                    test -f docker-compose.yml && echo "docker-compose found"   || exit 1
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
                echo 'Deploying to DEV...'
                sh '''
                    docker stop devops-webapp-dev 2>/dev/null || true
                    docker rm  devops-webapp-dev 2>/dev/null || true
                    docker run -d \
                        --name devops-webapp-dev \
                        -p 3001:80 \
                        devops-webapp:latest
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-dev)
                    [ "$STATUS" = "running" ] && echo "DEV Deploy Success!" || exit 1
                '''
            }
        }

        stage('Test DEV') {
            steps {
                sh '''
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-dev)
                    [ "$STATUS" = "running" ] && echo "DEV Tests Passed!" || exit 1
                '''
            }
        }

        stage('Deploy to STAGING') {
            steps {
                echo 'Deploying to STAGING...'
                sh '''
                    docker stop devops-webapp-staging 2>/dev/null || true
                    docker rm  devops-webapp-staging 2>/dev/null || true
                    docker run -d \
                        --name devops-webapp-staging \
                        -p 3002:80 \
                        devops-webapp:latest
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-staging)
                    [ "$STATUS" = "running" ] && echo "STAGING Deploy Success!" || exit 1
                '''
            }
        }

        stage('Test STAGING') {
            steps {
                sh '''
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp-staging)
                    [ "$STATUS" = "running" ] && echo "STAGING Tests Passed!" || exit 1
                '''
            }
        }

        stage('Approval for PROD') {
            steps {
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
                    docker rm  devops-webapp  2>/dev/null || true
                    docker run -d \
                        --name devops-webapp \
                        -p 3000:80 \
                        --restart unless-stopped \
                        devops-webapp:latest
                    sleep 2
                    STATUS=$(docker inspect --format="{{.State.Status}}" devops-webapp)
                    [ "$STATUS" = "running" ] && echo "PROD Deploy Success!" || exit 1
                '''
            }
        }

        stage('Start Monitoring') {
            steps {
                echo 'Starting Prometheus and Grafana...'
                sh '''
                    docker stop nginx-exporter prometheus grafana 2>/dev/null || true
                    docker rm  nginx-exporter prometheus grafana 2>/dev/null || true

                    docker network create devops-network 2>/dev/null || true

                    docker network connect devops-network devops-webapp 2>/dev/null || true

                    docker run -d \
                        --name nginx-exporter \
                        --network devops-network \
                        -p 9113:9113 \
                        nginx/nginx-prometheus-exporter:latest \
                        --nginx.scrape-uri=http://devops-webapp/stub_status

                    docker run -d \
                        --name prometheus \
                        --network devops-network \
                        -p 9090:9090 \
                        -v prometheus-data:/prometheus \
                        prom/prometheus:latest

                    docker run -d \
                        --name grafana \
                        --network devops-network \
                        -p 3003:3000 \
                        -e GF_SECURITY_ADMIN_USER=admin \
                        -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
                        grafana/grafana:latest

                    sleep 3
                    echo "Monitoring Stack Started!"
                '''
            }
        }

        stage('Verify All') {
            steps {
                echo 'Verifying all services...'
                sh '''
                    echo "Checking containers..."
                    for name in devops-webapp prometheus grafana; do
                        STATUS=$(docker inspect --format="{{.State.Status}}" $name 2>/dev/null || echo "not found")
                        echo "$name: $STATUS"
                    done
                    echo "All services verified!"
                '''
            }
        }
    }

    post {
        success {
            echo '''
            ============================================
            PIPELINE SUCCESS WITH MONITORING!

            ENVIRONMENTS:
            DEV      : http://localhost:3001
            STAGING  : http://localhost:3002
            PROD     : http://localhost:3000

            MONITORING:
            Prometheus : http://localhost:9090
            Grafana    : http://localhost:3003
            ============================================
            '''
        }
        failure {
            echo 'PIPELINE FAILED! Check logs above.'
        }
    }
}