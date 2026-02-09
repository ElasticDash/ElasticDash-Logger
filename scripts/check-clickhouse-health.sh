#!/bin/bash

# Check ClickHouse merge and background thread status
# Run this inside the ClickHouse container or with clickhouse-client

CONTAINER_NAME="${1:-langfuse-clickhouse}"

echo "=== ClickHouse Background Thread Status ==="
docker exec $CONTAINER_NAME clickhouse-client --query "
SELECT
    metric,
    value
FROM system.metrics
WHERE metric LIKE '%Background%'
   OR metric LIKE '%Merge%'
ORDER BY metric;
" 2>/dev/null || echo "Container not running. Run: docker-compose up -d"

echo ""
echo "=== Parts per Table (Active) ==="
docker exec $CONTAINER_NAME clickhouse-client --query "
SELECT
    database,
    table,
    count() AS parts_count,
    formatReadableSize(sum(bytes_on_disk)) AS disk_size
FROM system.parts
WHERE active = 1
GROUP BY database, table
ORDER BY parts_count DESC;
" 2>/dev/null

echo ""
echo "=== Current Merge Operations ==="
docker exec $CONTAINER_NAME clickhouse-client --query "
SELECT
    table,
    partition,
    progress,
    is_mutation
FROM system.merges;
" 2>/dev/null

echo ""
echo "=== Configuration Check ==="
docker exec $CONTAINER_NAME clickhouse-client --query "
SELECT
    name,
    value
FROM system.settings
WHERE name LIKE '%background%'
   OR name LIKE '%merge%'
ORDER BY name;
" 2>/dev/null
