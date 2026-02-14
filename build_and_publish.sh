#!/bin/bash
# build_and_publish.sh
# Build and publish ElasticDash web and worker Docker images with version tag
# Usage: bash build_and_publish.sh <version>

set -e

if [ -z "$1" ]; then
  echo "\nERROR: Version argument is required."
  echo "Usage: $0 <version>"
  echo "Example: bash $0 1.2.3"
  exit 1
fi

VERSION=$1
REPO="elasticdash"  # <-- Replace with your Docker Hub or registry username

# Build images

echo "Building elasticdash-web:$VERSION ..."
docker build -f web/Dockerfile -t $REPO/elasticdash-web:$VERSION .

echo "Building elasticdash-worker:$VERSION ..."
docker build -f worker/Dockerfile -t $REPO/elasticdash-worker:$VERSION .

# Push images

echo "Pushing elasticdash-web:$VERSION ..."
docker push $REPO/elasticdash-web:$VERSION

echo "Pushing elasticdash-worker:$VERSION ..."
docker push $REPO/elasticdash-worker:$VERSION

echo "\nBuild and publish complete!"
