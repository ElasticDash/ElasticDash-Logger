#!/bin/bash

# Monitor Docker build in real-time
# Run in a separate terminal while rebuild.sh is running

INTERVAL=5  # Update every 5 seconds

echo "📊 Docker Build Monitor (updating every ${INTERVAL}s)"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    clear
    
    echo "═════════════════════════════════════════"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker Build Status"
    echo "═════════════════════════════════════════"
    echo ""
    
    # CPU and Memory
    echo "💾 System Resources:"
    free -h | head -2 | tail -1
    echo ""
    
    echo "🔧 Docker Container Status:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No containers"
    echo ""
    
    echo "💾 Disk Usage:"
    df -h . | tail -1
    echo ""
    
    echo "🐳 Docker System Info:"
    docker system df 2>/dev/null | head -5 || echo "Unable to get info"
    echo ""
    
    echo "📝 Recent Build Log:"
    if [ -f rebuild.log ]; then
        tail -10 rebuild.log
    else
        echo "No rebuild.log found"
    fi
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Sleeping ${INTERVAL}s... (Ctrl+C to stop)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    sleep $INTERVAL
done
