#!/usr/bin/env bash
set -euo pipefail

# migrate_replace_volumes.sh
# Remove target volume → recreate → copy data from source volume

VOLUMES=(
  postgres_data
  clickhouse_data
  clickhouse_logs
  minio_data
)

SRC_PREFIX="elasticdash-logger_langfuse"
DEST_PREFIX="elasticdash-logger_elasticdash"

echo "=== Starting Volume Replacement Migration ==="

for v in "${VOLUMES[@]}"; do
  SRC="${SRC_PREFIX}_${v}"
  DEST="${DEST_PREFIX}_${v}"

  echo ""
  echo ">>> Migrating ${SRC} → ${DEST}"

  # Validate source exists
  if ! docker volume inspect "$SRC" >/dev/null 2>&1; then
    echo "ERROR: Source volume ${SRC} does not exist"
    exit 1
  fi

  # Remove destination volume if exists
  if docker volume inspect "$DEST" >/dev/null 2>&1; then
    echo "Removing existing destination volume ${DEST}"
    docker volume rm "$DEST"
  fi

  # Create clean destination
  docker volume create "$DEST"

  echo "Copying data..."

  docker run --rm \
    -v "${SRC}:/from:ro" \
    -v "${DEST}:/to" \
    ubuntu bash -c "
      set -e
      echo 'Source contents:'
      ls -lah /from || true

      cd /from
      tar cf - . | tar xf - -C /to
    "

  echo "Completed ${v}"
done

echo ""
echo "=== Migration Completed ==="
