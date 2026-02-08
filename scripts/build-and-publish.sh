#!/bin/bash
# build-and-publish.sh
# Builds Docker images for web and worker, tags with version, and pushes to Docker Hub.

set -e

# Set these variables as needed
DOCKER_USER="your-docker-username"
DOCKER_REPO_WEB="your-repo-web"
DOCKER_REPO_WORKER="your-repo-worker"
VERSION="${1:-latest}"

# Build web image
echo "Building web image..."
docker build -t "$DOCKER_USER/$DOCKER_REPO_WEB:$VERSION" -f ./web/Dockerfile .

echo "Pushing web image..."
docker push "$DOCKER_USER/$DOCKER_REPO_WEB:$VERSION"

# Build worker image
echo "Building worker image..."
docker build -t "$DOCKER_USER/$DOCKER_REPO_WORKER:$VERSION" -f ./worker/Dockerfile .

echo "Pushing worker image..."
docker push "$DOCKER_USER/$DOCKER_REPO_WORKER:$VERSION"

echo "Done."
