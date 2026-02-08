#!/bin/bash
# Rebuild all Docker images and restart all containers for ElasticDash-Logger

set -e

# Go to the project root (if not already there)
cd "$(dirname "$0")/.."

echo "[ElasticDash] Building and restarting all Docker containers..."


docker compose -f docker-compose.build.yml down
docker compose -f docker-compose.build.yml build --no-cache
docker compose -f docker-compose.build.yml up -d

echo "[ElasticDash] All containers rebuilt and restarted."
