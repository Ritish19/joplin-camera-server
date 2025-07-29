#!/bin/bash

# Backup Script for Joplin Server & Camera System
# This script creates backups of all important data

set -e

echo "🔄 Starting backup process..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Create backup directory with timestamp
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/joplin-usb/backups/$BACKUP_DATE"
mkdir -p "$BACKUP_DIR"

print_status "Creating backup in: $BACKUP_DIR"

# Use appropriate Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Backup PostgreSQL database
print_status "Backing up PostgreSQL database..."
$DOCKER_COMPOSE exec -T postgres pg_dump -U $POSTGRES_USER -d $POSTGRES_DB > "$BACKUP_DIR/postgres_backup.sql"

# Backup Joplin data directory
print_status "Backing up Joplin data..."
sudo tar -czf "$BACKUP_DIR/joplin_data.tar.gz" -C /mnt/joplin-usb joplin-data

# Backup camera data (if not too large)
print_status "Backing up camera configuration..."
sudo tar -czf "$BACKUP_DIR/camera_config.tar.gz" -C /mnt/joplin-usb camera-data --exclude="*.avi" --exclude="*.mp4"

# Backup configuration files
print_status "Backing up configuration files..."
tar -czf "$BACKUP_DIR/config_files.tar.gz" \
    docker-compose.yml \
    .env \
    nginx/ \
    config/ \
    scripts/ 2>/dev/null || true

# Create backup info file
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Backup Created: $(date)
System: $(uname -a)
Docker Compose Version: $($DOCKER_COMPOSE version --short)
Services Status:
$(docker ps --format "table {{.Names}}\t{{.Status}}")

Database Info:
Database: $POSTGRES_DB
User: $POSTGRES_USER

Included in this backup:
- PostgreSQL database dump
- Joplin data directory
- Camera configuration (without video files)
- All configuration files
EOF

# Set proper permissions
sudo chown -R $USER:$USER "$BACKUP_DIR"

# Clean up old backups (keep last 30 days)
print_status "Cleaning up old backups..."
find /mnt/joplin-usb/backups/ -type d -name "????????_??????" -mtime +${BACKUP_RETENTION_DAYS:-30} -exec rm -rf {} \; 2>/dev/null || true

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

print_success "Backup completed successfully!"
echo "Backup location: $BACKUP_DIR"
echo "Backup size: $BACKUP_SIZE"

# Optional: Upload to cloud storage (uncomment and configure as needed)
# print_status "Uploading to cloud storage..."
# rclone copy "$BACKUP_DIR" remote:joplin-backups/$BACKUP_DATE
