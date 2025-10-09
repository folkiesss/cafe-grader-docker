#!/bin/bash

# Cafe Grader Backup Script
# This script backs up the database and all volumes

set -e  # Exit on error

# Create backups directory if it doesn't exist
mkdir -p backups

# Get current timestamp for backup directory name (DD-MM-YYYY-HHMMSS format)
TIMESTAMP=$(date +"%d-%m-%Y-%H%M%S")
BACKUP_DIR="backups/${TIMESTAMP}"

# Create dedicated backup directory
mkdir -p "${BACKUP_DIR}"

echo "Starting Cafe Grader backup at $(date)"
echo "=========================================="
echo ""

echo "Backup directory: ${BACKUP_DIR}"
echo ""

# Backup 1: Database (SQL Dump)
echo "📦 Backing up database..."
docker exec cafe-grader-db sh -c 'mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" grader' 2>/dev/null > "${BACKUP_DIR}/grader-database.sql"
echo "✅ Database backup complete: ${BACKUP_DIR}/grader-database.sql"

# Backup 2: Storage Volume (test cases, problem files, uploads)
echo "📦 Backing up storage volume..."
docker run --rm \
  -v $(pwd)_cafe-grader-storage:/data \
  -v $(pwd)/${BACKUP_DIR}:/backup \
  alpine tar czf "/backup/grader-storage.tar.gz" -C /data .
echo "✅ Storage backup complete: ${BACKUP_DIR}/grader-storage.tar.gz"

# Backup 3: Cache Volume (judge data, compiled submissions)
echo "📦 Backing up cache volume..."
docker run --rm \
  -v $(pwd)_cafe-grader-cache:/data \
  -v $(pwd)/${BACKUP_DIR}:/backup \
  alpine tar czf "/backup/grader-cache.tar.gz" -C /data .
echo "✅ Cache backup complete: ${BACKUP_DIR}/grader-cache.tar.gz"

echo ""
echo "=========================================="
echo ""

echo "🎉 Backup completed successfully!"
echo ""

# Create portable archive in backups directory
echo "📦 Creating portable archive..."
ARCHIVE_NAME="backups/cafe-grader-backup-${TIMESTAMP}.tar.gz"
tar czf "${ARCHIVE_NAME}" -C backups "${TIMESTAMP}"
echo "✅ Portable archive created: ${ARCHIVE_NAME}"

# Remove the temporary backup directory to keep things clean
rm -rf "${BACKUP_DIR}"
echo "🧹 Cleaned up temporary files"

echo ""
echo "Archive:"
ls -lh "${ARCHIVE_NAME}" | awk '{print $9, "(" $5 ")"}'

echo ""
echo "To restore from this backup, use:"
echo "  ./restore.sh cafe-grader-backup-${TIMESTAMP}.tar.gz"
