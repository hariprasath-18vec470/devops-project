#!/bin/bash
set -e

ENVIRONMENT=$1
APP_NAME="devops-webapp"

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: ./deploy-multistage.sh [dev|staging|prod]"
    exit 1
fi

case $ENVIRONMENT in
    dev)
        PORT=3001
        TAG="dev-latest"
        ;;
    staging)
        PORT=3002
        TAG="staging-latest"
        ;;
    prod)
        PORT=3000
        TAG="prod-latest"
        ;;
    *)
        echo "Invalid environment: $ENVIRONMENT"
        exit 1
        ;;
esac

CONTAINER_NAME="${APP_NAME}-${ENVIRONMENT}"

echo "============================================"
echo " Deploying to: $ENVIRONMENT"
echo " Container   : $CONTAINER_NAME"
echo " Port        : $PORT"
echo " Tag         : $TAG"
echo "============================================"

echo "[1/4] Stopping old container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

echo "[2/4] Building image..."
docker build -t ${APP_NAME}:${TAG} .

echo "[3/4] Starting container..."
docker run -d \
    --name $CONTAINER_NAME \
    -p $PORT:80 \
    --restart unless-stopped \
    ${APP_NAME}:${TAG}

echo "[4/4] Verifying..."
sleep 2
STATUS=$(docker inspect --format="{{.State.Status}}" $CONTAINER_NAME)

if [ "$STATUS" = "running" ]; then
    echo "Deployment to $ENVIRONMENT Successful!"
    echo "App running at: http://localhost:$PORT"
else
    echo "Deployment Failed!"
    exit 1
fi