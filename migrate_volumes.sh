#!/bin/bash

# migrate_volumes.sh
# Migrate Docker volumes from elasticdash_* to langfuse_*
# Usage: bash migrate_volumes.sh


set -e


# Define source (langfuse_*) and target (elasticdash_*) volume names
VOLUMES=(
  "postgres_data"
  "clickhouse_data"
  "clickhouse_logs"
  "minio_data"
)


for v in "${VOLUMES[@]}"; do
  SRC="langfuse_${v}"
  DEST="elasticdash_${v}"
  echo "Migrating $SRC → $DEST ..."

  # Remove destination volume if it exists
  if docker volume inspect "$DEST" >/dev/null 2>&1; then
    echo "Removing existing $DEST volume..."
    docker volume rm "$DEST"
  fi

  # Create a fresh destination volume
  docker volume create "$DEST"

  # Copy data from source to destination
  docker run --rm \
    -v "$SRC:/from" \
    -v "$DEST:/to" \
    alpine ash -c "cd /from && cp -a . /to"
done

echo "\nMigration complete!"
echo "Verify your data, then remove old volumes with:"
echo "  docker volume rm langfuse_postgres_data langfuse_clickhouse_data langfuse_clickhouse_logs langfuse_minio_data"