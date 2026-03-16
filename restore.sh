#!/bin/bash

# Cafe Grader Restore Script
# This script restores the database and all volumes from a backup

set -e  # Exit on error

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <archive_file>"
    echo ""
    echo "Available backup archives:"
    
    # List all backups sorted by time (newest first)
    BACKUPS=$(ls -1t backups/cafe-grader-backup-*.tar.gz 2>/dev/null | sed 's|backups/||')
    
    if [ -z "$BACKUPS" ]; then
        echo "  No backups found"
    else
        LATEST=$(echo "$BACKUPS" | head -1)
        echo "$BACKUPS" | while read backup; do
            if [ "$backup" = "$LATEST" ]; then
                echo "  $backup (latest)"
            else
                echo "  $backup"
            fi
        done
    fi
    
    exit 1
fi

# Check if file exists as-is or in backups directory
if [ -f "$1" ]; then
    ARCHIVE_FILE="$1"
elif [ -f "backups/$1" ]; then
    ARCHIVE_FILE="backups/$1"
else
    echo "❌ Error: Archive file not found: $1"
    echo "❌ Also checked: backups/$1"
    exit 1
fi

echo "📦 Extracting backup archive..."
EXTRACTED_DIR=$(tar tzf "${ARCHIVE_FILE}" | head -1 | cut -f1 -d"/")

# Extract to temporary directory
TEMP_EXTRACT_DIR=$(mktemp -d)
tar xzf "${ARCHIVE_FILE}" -C "${TEMP_EXTRACT_DIR}"
echo "✅ Archive extracted"

BACKUP_DIR="${TEMP_EXTRACT_DIR}/${EXTRACTED_DIR}"
CLEANUP_AFTER_RESTORE=true

# Get the parent directory name for Docker Compose volume prefix
PROJECT_NAME=$(basename "$(pwd)")

# Check if backup files exist
if [ ! -f "${BACKUP_DIR}/grader-database.sql" ]; then
    echo "❌ Error: Database backup file not found: ${BACKUP_DIR}/grader-database.sql"
    exit 1
fi

if [ ! -f "${BACKUP_DIR}/grader-storage.tar.gz" ]; then
    echo "❌ Error: Storage backup file not found: ${BACKUP_DIR}/grader-storage.tar.gz"
    exit 1
fi

if [ ! -f "${BACKUP_DIR}/grader-cache.tar.gz" ]; then
    echo "❌ Error: Cache backup file not found: ${BACKUP_DIR}/grader-cache.tar.gz"
    exit 1
fi

echo "Starting Cafe Grader restore at $(date)"
echo "=========================================="
echo "⚠️  WARNING: This will overwrite current data!"
echo ""
read -p "Are you sure you want to continue? (y/N): " confirm

# Convert to lowercase for comparison
confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Restore 1: Database
echo ""
echo "📥 Restoring database..."
docker exec -i cafe-grader-db sh -c 'mysql -u root -p"$MYSQL_ROOT_PASSWORD" grader' 2>/dev/null < "${BACKUP_DIR}/grader-database.sql"
echo "✅ Database restore complete"

# Restore 2: Storage Volume
echo "📥 Restoring storage volume..."
docker run --rm \
  -v "${PROJECT_NAME}_cafe-grader-storage":/data \
  -v "${BACKUP_DIR}":/backup \
  alpine sh -c "rm -rf /data/* && cd /data && tar xzf /backup/grader-storage.tar.gz"
echo "✅ Storage restore complete"

# Restore 3: Cache Volume
echo "📥 Restoring cache volume..."
docker run --rm \
  -v "${PROJECT_NAME}_cafe-grader-cache":/data \
  -v "${BACKUP_DIR}":/backup \
  alpine sh -c "rm -rf /data/* && cd /data && tar xzf /backup/grader-cache.tar.gz"
echo "✅ Cache restore complete"

echo "=========================================="
echo "🎉 Restore completed successfully!"

# Clean up extracted directory
if [ "$CLEANUP_AFTER_RESTORE" = true ]; then
    echo "🧹 Cleaning up temporary files..."
    rm -rf "${TEMP_EXTRACT_DIR}"
fi

echo ""
echo "You may need to restart the containers:"
echo "  docker compose restart"