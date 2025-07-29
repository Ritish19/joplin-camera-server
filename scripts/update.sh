#!/bin/bash

# Update Script for Joplin Server & Camera System
# This script updates the system from GitHub repository

set -e

echo "🔄 Starting system update..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed"
    exit 1
fi

# Use appropriate Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Backup current configuration
print_status "Creating backup before update..."
./scripts/backup.sh

# Stash any local changes
print_status "Stashing local changes..."
git stash push -m "Auto-stash before update $(date)"

# Pull latest changes from repository
print_status "Pulling latest changes from repository..."
git pull origin main

# Check if docker-compose.yml changed
if git diff HEAD~1 HEAD --name-only | grep -q "docker-compose.yml"; then
    print_warning "docker-compose.yml has been updated. Services will be restarted."
    RESTART_REQUIRED=true
else
    RESTART_REQUIRED=false
fi

# Pull latest Docker images
print_status "Pulling latest Docker images..."
$DOCKER_COMPOSE pull

# Restart services if needed
if [ "$RESTART_REQUIRED" = true ]; then
    print_status "Restarting services due to configuration changes..."
    $DOCKER_COMPOSE down
    $DOCKER_COMPOSE up -d
else
    print_status "Updating containers with new images..."
    $DOCKER_COMPOSE up -d --remove-orphans
fi

# Wait for services to stabilize
print_status "Waiting for services to stabilize..."
sleep 30

# Check service health
print_status "Checking service health..."
$DOCKER_COMPOSE ps

# Show any service that's not running
for service in postgres joplin motioneye nginx fail2ban; do
    if ! $DOCKER_COMPOSE ps $service | grep -q "Up"; then
        print_warning "Service $service is not running properly. Check logs:"
        echo "$DOCKER_COMPOSE logs $service"
    fi
done

print_success "Update completed successfully!"
echo ""
print_status "📊 To check logs: $DOCKER_COMPOSE logs -f"
print_status "🔄 To restart a specific service: $DOCKER_COMPOSE restart [service-name]"

# Show git log of changes
echo ""
print_status "Recent changes:"
git log --oneline -5
