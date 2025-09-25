#!/bin/bash

# Build script for linkerd-await Docker image
set -euo pipefail

# Configuration
REGISTRY="398878272913.dkr.ecr.eu-west-1.amazonaws.com"
IMAGE_NAME="linkerd-await"
TAG="v0.3.1"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building linkerd-await Docker image..."

# Build the image
docker build \
    --build-arg LINKERD_AWAIT_VERSION=v0.3.1 \
    --platform linux/amd64 \
    -t "${IMAGE_NAME}:${TAG}" \
    -t "${IMAGE_NAME}:latest" \
    -t "${FULL_IMAGE}" \
    "${SCRIPT_DIR}"

echo "Image built successfully: ${IMAGE_NAME}:${TAG}"

# Authenticate with ECR
echo "Authenticating with ECR..."
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin "${REGISTRY}"

# Create ECR repository if it doesn't exist
echo "Ensuring ECR repository exists..."
aws ecr describe-repositories --repository-names "${IMAGE_NAME}" --region eu-west-1 >/dev/null 2>&1 || \
aws ecr create-repository --repository-name "${IMAGE_NAME}" --region eu-west-1

# Push the image
echo "Pushing image to ECR..."
docker push "${FULL_IMAGE}"

echo "✅ Successfully built and pushed: ${FULL_IMAGE}"
echo "✅ Update your Helm values to use: ${FULL_IMAGE}"