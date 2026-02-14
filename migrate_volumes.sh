#!/bin/bash
# migrate_volumes.sh
# Migrate Docker volumes from langfuse_* to elasticdash_*
# Usage: bash migrate_volumes.sh

set -e

# Define old and new volume names
VOLUMES=(
  "postgres_data"
  "clickhouse_data"
  "clickhouse_logs"
  "minio_data"
)

for v in "${VOLUMES[@]}"; do
  OLD="langfuse_${v}"
  NEW="elasticdash_${v}"
  echo "Migrating $OLD -> $NEW ..."

  # Create new volume if it doesn't exist
  if ! docker volume inspect "$NEW" >/dev/null 2>&1; then
    docker volume create "$NEW"
  fi

  # Copy data from old to new
  docker run --rm -it \
    -v "$OLD:/from" \
    -v "$NEW:/to" \
    alpine ash -c "cd /from && cp -a . /to"

done

echo "\nMigration complete!"
echo "Verify your data, then remove old volumes with:"
echo "  docker volume rm langfuse_postgres_data langfuse_clickhouse_data langfuse_clickhouse_logs langfuse_minio_data"