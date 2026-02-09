# ClickHouse CPU Optimization for MergeTree Background Processes

## Problem Identified

ClickHouse was experiencing high CPU consumption due to:
- **MergeTree background merge processes** running with unlimited threads (48 threads active)
- Heavy log ingestion creating thousands of small parts
- No CPU or merge thread limits configured

**Symptoms:**
- CPU usage at 100% despite low query load
- `MergeTreeBackgroundExecutorThreadsActive = 48`
- Massive number of merge operations (`MergeParts = 61`)
- Uncompressed data being scanned: ~36GB

## Solution Applied

### 1. **ClickHouse Configuration** (`clickhouse-config.xml`)

Created a custom ClickHouse config with safe defaults:

```xml
<background_pool_size>8</background_pool_size>
<!-- Limits background merge threads from 48 → 8 -->

<background_schedule_pool_size>8</background_schedule_pool_size>
<!-- Limits scheduled background tasks to 8 threads -->

<max_background_merges_mutations_concurrency_ratio>0.3</max_background_merges_mutations_concurrency_ratio>
<!-- Only 30% of CPU cores for merges/mutations -->

<merge_selecting_sleep_ms>5000</merge_selecting_sleep_ms>
<!-- Reduce merge selection frequency (less aggressive merging) -->
```

### 2. **Docker Compose Resource Limits** (`docker-compose.build.yml` & `docker-compose.dev.yml`)

Added hard limits:

```yaml
cpus: '4'           # Max 4 CPU cores
mem_limit: 8g       # Max 8GB memory
```

### 3. **Configuration Mount**

ClickHouse container now mounts the config:

```yaml
volumes:
  - ./clickhouse-config.xml:/etc/clickhouse-server/config.d/custom-limits.xml
```

## Expected CPU Reduction

**Before:**
- All 48 background threads active
- CPU: 100%
- Aggressive merging

**After:**
- Max 8 background threads
- CPU: ~20-30% (depending on ingestion rate)
- Controlled, scheduled merging

## How to Deploy

### Step 1: Rebuild with new config

```bash
./scripts/rebuild.sh
```

The new ClickHouse configuration will be mounted during container startup.

### Step 2: Verify CPU reduction

Watch Docker resource usage:

```bash
docker stats langfuse-clickhouse
```

Expected:
- CPU drops to 20-30%
- Merges still happening (background), just slower

### Step 3: Monitor merge progress

Run the diagnostic script:

```bash
./scripts/check-clickhouse-health.sh
```

Output will show:
- Current background threads in use
- Number of parts per table
- Active merge operations
- Configuration validation

## Fine-tuning Guide

If CPU still too high, adjust `clickhouse-config.xml`:

### ⚡ More aggressive (lower CPU)
```xml
<background_pool_size>4</background_pool_size>
<background_schedule_pool_size>4</background_schedule_pool_size>
<max_background_merges_mutations_concurrency_ratio>0.2</max_background_merges_mutations_concurrency_ratio>
```

### ⚙️ More balanced (better performance)
```xml
<background_pool_size>12</background_pool_size>
<background_schedule_pool_size>12</background_schedule_pool_size>
<max_background_merges_mutations_concurrency_ratio>0.4</max_background_merges_mutations_concurrency_ratio>
```

### 🚀 Higher throughput (higher CPU)
```xml
<background_pool_size>16</background_pool_size>
<background_schedule_pool_size>16</background_schedule_pool_size>
<max_background_merges_mutations_concurrency_ratio>0.5</max_background_merges_mutations_concurrency_ratio>
```

## Emergency: Stop Merges Temporarily

If CPU still critical:

```bash
docker exec langfuse-clickhouse clickhouse-client -q "SYSTEM STOP MERGES;"
```

Resume later:

```bash
docker exec langfuse-clickhouse clickhouse-client -q "SYSTEM START MERGES;"
```

⚠️ **Warning:** Do not leave merges stopped for extended periods — parts will accumulate.

## Long-term Solutions

### 1. Optimize Ingestion Batching
- Batch inserts (1000+ rows per batch)
- Reduces number of parts created

### 2. Review Partition Strategy
- Current: `PARTITION BY toYYYYMMDD(timestamp)` (1 partition per day)
- Consider: `PARTITION BY toYYYYMM(timestamp)` (1 partition per month)

### 3. Log Retention Policy
- Don't store verbose logs forever
- Implement TTL (Time To Live):

```sql
ALTER TABLE system_logs MODIFY TTL date + INTERVAL 30 DAY;
```

## Monitoring

Key metrics to track:

```bash
# Check regularly
./scripts/check-clickhouse-health.sh

# Watch CPU in real-time
docker stats langfuse-clickhouse

# Check query performance
docker exec langfuse-clickhouse clickhouse-client -q "
  SELECT query, duration_ms FROM system.query_log 
  WHERE type='QueryFinish' 
  ORDER BY duration_ms DESC 
  LIMIT 10;"
```

## References

- ClickHouse Background Process Docs: https://clickhouse.com/docs/en/operations/server-configuration-parameters
- MergeTree Engine: https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree
- Merge Tuning: https://clickhouse.com/docs/en/development/settings#merge-tree-settings
