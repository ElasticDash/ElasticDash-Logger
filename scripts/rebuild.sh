#!/bin/bash

set -e

COMPOSE_FILE="docker-compose.build.yml"
LOG_FILE="rebuild.log"

echo "🔧 Starting safe rebuild with resource management..."
echo "Build log: $LOG_FILE"
echo ""

# Function to handle cleanup on exit
cleanup() {
    echo ""
    echo "⚠️  Interrupt caught. Attempting cleanup..."
    # Force stop without waiting
    docker-compose -f $COMPOSE_FILE kill 2>/dev/null || true
    docker-compose -f $COMPOSE_FILE down --remove-orphans --force 2>/dev/null || true
    exit 1
}

trap cleanup SIGINT SIGTERM

# ============================================================================
# STEP 1: CHECK IF SYSTEM IS ALREADY JAMMED
# ============================================================================
echo "🔍 Checking if system is responsive..."
RESPONSE_CHECK=0
timeout 5 docker ps > /dev/null 2>&1 || RESPONSE_CHECK=$?

if [ $RESPONSE_CHECK -ne 0 ]; then
    echo "❌ ERROR: Docker daemon is not responding!"
    echo ""
    echo "System is likely jammed. Your options:"
    echo "1. Wait 2-3 minutes and try again (system might recover)"
    echo "2. Run: systemctl restart docker"
    echo "3. Restart EC2 instance (nuclear option)"
    echo ""
    exit 1
fi
echo "✅ Docker daemon is responsive"

# ============================================================================
# STEP 2: CHECK DISK SPACE (need at least 10GB free)
# ============================================================================
echo ""
echo "📊 Checking disk space..."
AVAILABLE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE" -lt 10 ]; then
    echo "❌ ERROR: Only ${AVAILABLE}GB free. Need at least 10GB for build."
    echo ""
    echo "Solutions:"
    echo "1. Delete old images: docker image prune -af"
    echo "2. Delete volumes: docker volume prune -f"
    echo "3. Clear Docker system: docker system prune -af --volumes"
    exit 1
fi
echo "✅ Disk space OK: ${AVAILABLE}GB available"

# ============================================================================
# STEP 3: CHECK ClickHouse CPU - if maxed, warn user
# ============================================================================
echo ""
echo "⚠️  Checking ClickHouse CPU usage..."
CLICKHOUSE_CPU=$(docker stats --no-stream langfuse-clickhouse 2>/dev/null | tail -1 | awk '{print $3}' | sed 's/%//' | cut -d. -f1 || echo "0")
if [ "$CLICKHOUSE_CPU" -gt 80 ] 2>/dev/null; then
    echo "⚠️  WARNING: ClickHouse is consuming ${CLICKHOUSE_CPU}% CPU!"
    echo ""
    echo "This might cause build to hang. Waiting 10 seconds for it to settle..."
    for i in {10..1}; do
        echo -n "$i... "
        sleep 1
    done
    echo ""
fi

# ============================================================================
# STEP 4: AGGRESSIVE CLEANUP - KILL FIRST, WAIT LATER
# ============================================================================
echo ""
echo "🛑 Stopping containers (with timeout)..."

# Kill containers aggressively (don't wait for graceful shutdown)
echo "   - Killing ClickHouse (might be CPU-heavy)..."
timeout 10 docker kill langfuse-clickhouse 2>/dev/null || echo "   (already stopped or timed out)"

echo "   - Killing other services..."
timeout 20 docker-compose -f $COMPOSE_FILE kill 2>/dev/null || echo "   (timed out - force removing)"

# Allow system to breathe for 5 seconds
echo "   - Waiting for resources to free up (5 seconds)..."
sleep 5

# Remove everything (force if needed)
echo "   - Removing containers..."
timeout 10 docker-compose -f $COMPOSE_FILE down --remove-orphans --force 2>/dev/null || true

# Extra cleanup if still hanging
docker ps -a -q 2>/dev/null | xargs -r timeout 5 docker rm -f 2>/dev/null || true

echo "✅ Containers stopped"

# ============================================================================
# STEP 5: DOCKER SYSTEM CLEANUP
# ============================================================================
echo ""
echo "🧹 Cleaning up Docker resources..."

# This can hang if Docker daemon is overloaded - so timeout it
timeout 30 docker system prune -f --volumes 2>&1 | head -5 || echo "   (prune timed out - continuing anyway)"

echo "✅ Cleanup complete"

# ============================================================================
# STEP 6: BUILD WITH TIMEOUT
# ============================================================================
echo ""
echo "🏗️  Building Docker images (timeout: 30 minutes)..."
echo "   Tip: Monitor in another terminal: ./scripts/monitor-build.sh"
echo ""

# Build with 30-minute timeout
timeout 1800 docker-compose -f $COMPOSE_FILE build --no-cache 2>&1 | tee -a $LOG_FILE

BUILD_RESULT=$?
if [ $BUILD_RESULT -eq 124 ]; then
    echo ""
    echo "❌ BUILD TIMEOUT! Build exceeded 30 minutes."
    echo ""
    echo "This usually means:"
    echo "1. ClickHouse is still consuming too much CPU"
    echo "2. EC2 instance type is too small (t3.micro/small)"
    echo "3. Disk I/O is very slow"
    echo ""
    echo "Solutions:"
    echo "1. Restart EC2 instance"
    echo "2. Upgrade to t3.large or larger"
    echo "3. Check disk type: lsblk (should be gp3, not gp2)"
    exit 1
fi

if [ $BUILD_RESULT -ne 0 ]; then
    echo ""
    echo "❌ Build failed with error code: $BUILD_RESULT"
    echo "Check rebuild.log for details"
    exit 1
fi

echo ""
echo "✅ Build completed successfully!"

# ============================================================================
# STEP 7: VERIFY IMAGES
# ============================================================================
echo ""
echo "🔍 Verifying built images..."
docker images | grep -E "langfuse|postgres|clickhouse|redis|minio" | head -5

# ============================================================================
# STEP 8: START CONTAINERS
# ============================================================================
echo ""
echo "🚀 Starting containers..."
timeout 60 docker-compose -f $COMPOSE_FILE up -d 2>&1 | tee -a $LOG_FILE || {
    echo "❌ Failed to start containers"
    exit 1
}

# ============================================================================
# STEP 9: WAIT FOR SERVICES TO BE READY
# ============================================================================
echo ""
echo "⏳ Waiting for services to be ready (timeout: 2 minutes)..."

RETRY=24
while [ $RETRY -gt 0 ]; do
    if timeout 5 docker exec langfuse-web curl -sf http://localhost:3000/api/public/health > /dev/null 2>&1; then
        echo "✅ Web service is healthy!"
        break
    fi
    RETRY=$((RETRY - 1))
    if [ $RETRY -gt 0 ]; then
        echo "⏳ Waiting... ($RETRY retries left)"
        sleep 5
    fi
done

if [ $RETRY -eq 0 ]; then
    echo ""
    echo "⚠️  Web service didn't respond within 2 minutes"
    echo "Check logs:"
    echo "   docker-compose -f $COMPOSE_FILE logs -f langfuse-web"
    exit 1
fi

# ============================================================================
# STEP 10: SUCCESS SUMMARY
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ REBUILD COMPLETE!"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Services status:"
docker-compose -f $COMPOSE_FILE ps 2>/dev/null || true

echo ""
echo "📍 Access URLs:"
echo "   • Web UI:         http://localhost:3002"
echo "   • Worker Health:  http://localhost:3030/api/health"
echo "   • MinIO Console:  http://localhost:9091"
echo "   • ClickHouse:     http://localhost:8123"
echo ""

echo "📊 Check ClickHouse CPU (should be low now):"
echo "   ./scripts/check-clickhouse-health.sh"
echo ""

echo "📈 Monitor real-time in another terminal:"
echo "   docker stats"
echo ""

echo "📝 View logs:"
echo "   docker-compose -f $COMPOSE_FILE logs -f"
echo ""