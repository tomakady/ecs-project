#!/bin/bash
set -e

# Configuration
AWS_REGION="eu-west-2"
ECR_REPO="773913840750.dkr.ecr.eu-west-2.amazonaws.com/memos-dev"
IMAGE_TAG="latest"

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

echo "🐳 Building Docker image..."
cd app
docker build -t memos:${IMAGE_TAG} .

echo "🏷️  Tagging image..."
docker tag memos:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}

echo "📤 Pushing to ECR..."
docker push ${ECR_REPO}:${IMAGE_TAG}

echo "✅ Done! Image pushed to ${ECR_REPO}:${IMAGE_TAG}"
