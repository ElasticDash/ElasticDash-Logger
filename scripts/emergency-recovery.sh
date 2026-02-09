#!/bin/bash

# Emergency recovery script for stuck Docker builds
# Use when docker-compose build is hanging

set -e

echo "🆘 Docker Recovery - Clearing stuck processes and resources"
echo ""

# Step 1: Force kill any stuck docker or build processes
echo "🔪 Killing stuck Docker processes..."
docker-compose -f docker-compose.build.yml kill 2>/dev/null || true
docker-compose -f docker-compose.build.yml down --remove-orphans --force 2>/dev/null || true

# Step 2: Stop all containers
echo "🛑 Stopping all containers..."
docker ps -q | xargs -r docker stop -t 5

# Step 3: Remove dangling containers
echo "🗑️  Removing dangling containers..."
docker ps -a -q | xargs -r docker rm -f

# Step 4: Prune system
echo "🧹 Pruning Docker system..."
docker system prune -af --volumes

# Step 5: Check disk space
echo ""
echo "📊 Disk space after cleanup:"
df -h . | tail -1

# Step 6: Check memory
echo ""
echo "💾 Available memory:"
free -h | grep Mem

# Step 7: Show Docker stats
echo ""
echo "📈 Current Docker resource usage:"
docker stats --no-stream --all 2>/dev/null || echo "No containers running"

echo ""
echo "═══════════════════════════════════════"
echo "✅ RECOVERY COMPLETE"
echo "═══════════════════════════════════════"
echo ""
echo "System is now cleaned up. Try again:"
echo "  ./scripts/rebuild.sh"
echo ""
echo "If still having issues:"
echo "  1. Check EC2 instance size (need at least t3.large)"
echo "  2. Increase disk space if full"
echo "  3. Check: docker system df"
echo ""
