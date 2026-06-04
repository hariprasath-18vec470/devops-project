#!/bin/bash
set -e

echo "=============================="
echo " 🚀 DevOps Deployment Script"
echo "=============================="

APP_NAME="devops-webapp"
IMAGE_TAG="latest"
HOST_PORT=3000

echo "[1/4] Stopping old container (if any)..."
docker stop $APP_NAME 2>/dev/null || echo "No running container found."
docker rm $APP_NAME 2>/dev/null || echo "No container to remove."

echo "[2/4] Building Docker image..."
docker build -t $APP_NAME:$IMAGE_TAG .

echo "[3/4] Running new container..."
docker run -d \
  --name $APP_NAME \
  -p $HOST_PORT:80 \
  --restart unless-stopped \
  $APP_NAME:$IMAGE_TAG

echo "[4/4] Verifying deployment..."
sleep 2
STATUS=$(docker inspect --format='{{.State.Status}}' $APP_NAME)

if [ "$STATUS" == "running" ]; then
  echo "✅ Deployment Successful!"
  echo "🌐 App running at: http://localhost:$HOST_PORT"
else
  echo "❌ Deployment Failed!"
  exit 1
fi