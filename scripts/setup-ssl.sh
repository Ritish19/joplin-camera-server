#!/bin/bash

# SSL Certificate Setup Script
# This script helps set up SSL certificates for the domains

set -e

echo "🔐 SSL Certificate Setup"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
if [ -f ".env" ]; then
    source .env
else
    print_error ".env file not found"
    exit 1
fi

# Create SSL directory
mkdir -p nginx/ssl

print_status "SSL Certificate Setup Options:"
echo "1. Generate self-signed certificates (for testing)"
echo "2. Use Let's Encrypt with Certbot (recommended for production)"
echo "3. Use existing certificates"
echo ""
read -p "Choose an option (1-3): " choice

case $choice in
    1)
        print_status "Generating self-signed certificates..."
        
        # Generate certificates for Joplin subdomain
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/joplin.${DOMAIN_NAME}.key \
            -out nginx/ssl/joplin.${DOMAIN_NAME}.crt \
            -subj "/C=NP/ST=Bagmati/L=Kathmandu/O=Personal/CN=joplin.${DOMAIN_NAME}"
        
        # Generate certificates for Camera subdomain
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/camera.${DOMAIN_NAME}.key \
            -out nginx/ssl/camera.${DOMAIN_NAME}.crt \
            -subj "/C=NP/ST=Bagmati/L=Kathmandu/O=Personal/CN=camera.${DOMAIN_NAME}"
        
        print_success "Self-signed certificates generated"
        print_warning "Remember to accept the security warning in your browser"
        ;;
        
    2)
        print_status "Setting up Let's Encrypt certificates..."
        
        # Check if certbot is installed
        if ! command -v certbot &> /dev/null; then
            print_status "Installing certbot..."
            sudo apt update
            sudo apt install -y certbot python3-certbot-nginx
        fi
        
        # Stop nginx temporarily
        docker-compose stop nginx || true
        
        # Generate certificates
        print_status "Requesting certificate for joplin.${DOMAIN_NAME}..."
        sudo certbot certonly --standalone \
            -d joplin.${DOMAIN_NAME} \
            --email admin@${DOMAIN_NAME} \
            --agree-tos \
            --non-interactive
        
        print_status "Requesting certificate for camera.${DOMAIN_NAME}..."
        sudo certbot certonly --standalone \
            -d camera.${DOMAIN_NAME} \
            --email admin@${DOMAIN_NAME} \
            --agree-tos \
            --non-interactive
        
        # Copy certificates to nginx directory
        sudo cp /etc/letsencrypt/live/joplin.${DOMAIN_NAME}/fullchain.pem nginx/ssl/joplin.${DOMAIN_NAME}.crt
        sudo cp /etc/letsencrypt/live/joplin.${DOMAIN_NAME}/privkey.pem nginx/ssl/joplin.${DOMAIN_NAME}.key
        sudo cp /etc/letsencrypt/live/camera.${DOMAIN_NAME}/fullchain.pem nginx/ssl/camera.${DOMAIN_NAME}.crt
        sudo cp /etc/letsencrypt/live/camera.${DOMAIN_NAME}/privkey.pem nginx/ssl/camera.${DOMAIN_NAME}.key
        
        # Set proper permissions
        sudo chown $USER:$USER nginx/ssl/*
        chmod 600 nginx/ssl/*.key
        
        # Start nginx
        docker-compose start nginx
        
        print_success "Let's Encrypt certificates installed"
        print_status "Setting up auto-renewal..."
        
        # Add renewal cron job
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'docker-compose -f $(pwd)/docker-compose.yml restart nginx'") | crontab -
        
        print_success "Auto-renewal configured"
        ;;
        
    3)
        print_status "Please place your certificates in the nginx/ssl/ directory:"
        echo "- joplin.${DOMAIN_NAME}.crt and joplin.${DOMAIN_NAME}.key"
        echo "- camera.${DOMAIN_NAME}.crt and camera.${DOMAIN_NAME}.key"
        echo ""
        read -p "Press Enter when certificates are in place..."
        
        # Check if certificates exist
        if [ -f "nginx/ssl/joplin.${DOMAIN_NAME}.crt" ] && [ -f "nginx/ssl/joplin.${DOMAIN_NAME}.key" ] && \
           [ -f "nginx/ssl/camera.${DOMAIN_NAME}.crt" ] && [ -f "nginx/ssl/camera.${DOMAIN_NAME}.key" ]; then
            print_success "Certificates found"
        else
            print_error "Required certificates not found"
            exit 1
        fi
        ;;
        
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

# Generate htpasswd for camera basic auth
print_status "Setting up camera basic authentication..."
read -p "Enter username for camera access: " camera_user
read -s -p "Enter password for camera access: " camera_pass
echo ""

# Install htpasswd if not available
if ! command -v htpasswd &> /dev/null; then
    sudo apt update
    sudo apt install -y apache2-utils
fi

# Create htpasswd file
htpasswd -cb nginx/ssl/.htpasswd "$camera_user" "$camera_pass"

print_success "SSL setup completed!"
print_status "You can now access your services securely:"
echo "- Joplin: https://joplin.${DOMAIN_NAME}"
echo "- Camera: https://camera.${DOMAIN_NAME} (username: $camera_user)"
