#!/bin/bash

# Joplin Server & Camera System Deployment Script
# This script deploys the complete stack on Raspberry Pi

set -e  # Exit on any error

echo "🚀 Starting Joplin Server & Camera System Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

print_status "Loading environment variables..."
source .env

# Check required directories
print_status "Checking and creating required directories..."
sudo mkdir -p /mnt/joplin-usb/{joplin-data,postgres-data,postgres-backup,camera-data,nginx-logs}
sudo chown -R $USER:$USER /mnt/joplin-usb/

# Create SSL directory
mkdir -p nginx/ssl

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Use appropriate Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

print_status "Using Docker Compose: $DOCKER_COMPOSE"

# Pull latest images
print_status "Pulling latest Docker images..."
$DOCKER_COMPOSE pull

# Stop existing containers
print_status "Stopping existing containers..."
$DOCKER_COMPOSE down || true

# Start the services
print_status "Starting services..."
$DOCKER_COMPOSE up -d

# Wait for services to be healthy
print_status "Waiting for services to start..."
sleep 30

# Check service status
print_status "Checking service status..."
$DOCKER_COMPOSE ps

# Test database connection
print_status "Testing database connection..."
if $DOCKER_COMPOSE exec postgres pg_isready -U $POSTGRES_USER > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_warning "Database might not be ready yet"
fi

# Show logs for any failed services
print_status "Checking for any service errors..."
for service in postgres joplin motioneye nginx fail2ban; do
    if ! $DOCKER_COMPOSE ps $service | grep -q "Up"; then
        print_warning "Service $service is not running. Showing logs:"
        $DOCKER_COMPOSE logs --tail=20 $service
    fi
done

print_success "Deployment completed!"
echo ""
print_status "📝 Next steps:"
echo "1. Configure your domain DNS to point to your Cloudflare tunnel"
echo "2. Set up SSL certificates (run ./scripts/setup-ssl.sh)"
echo "3. Create camera basic auth credentials"
echo "4. Access your services:"
echo "   - Joplin: https://joplin.$DOMAIN_NAME"
echo "   - Camera: https://camera.$DOMAIN_NAME"
echo ""
print_status "📊 To monitor logs: $DOCKER_COMPOSE logs -f"
print_status "🔄 To restart services: $DOCKER_COMPOSE restart"
print_status "🛑 To stop services: $DOCKER_COMPOSE down"
