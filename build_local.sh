#!/bin/bash
# build_local.sh
# Build ElasticDash web and worker Docker images locally (no push)

set -e

echo "Building elasticdash-web..."
docker build -f web/Dockerfile -t elasticdash-web:latest .

echo "Building elasticdash-worker..."
docker build -f worker/Dockerfile -t elasticdash-worker:latest .

echo "\nBuild complete! Images:"
docker images | grep elasticdash-
