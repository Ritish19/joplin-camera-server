#!/bin/bash

# SSL Certificate Setup Script for Joplin Server
# This script sets up Let's Encrypt SSL certificates for your domains

set -e

echo "🔐 Setting up SSL certificates for Joplin Server..."

# Source environment variables
source .env

# Ensure required directories exist
sudo mkdir -p /media/pi/joplin-server/certbot-webroot
sudo mkdir -p /media/pi/joplin-server/certbot-certs
sudo mkdir -p /media/pi/joplin-server/certbot-logs

# Set permissions
sudo chown -R pi:pi /media/pi/joplin-server/certbot-*

echo "📋 Certificate setup for domains:"
echo "  - joplin.${DOMAIN_NAME}"
echo "  - camera.${DOMAIN_NAME}"
echo ""

# Check if domain points to current IP
CURRENT_IP=$(curl -s ifconfig.me)
JOPLIN_IP=$(nslookup joplin.${DOMAIN_NAME} | grep "Address:" | tail -1 | cut -d' ' -f2)
CAMERA_IP=$(nslookup camera.${DOMAIN_NAME} | grep "Address:" | tail -1 | cut -d' ' -f2)

echo "🌐 Domain verification:"
echo "  Current public IP: $CURRENT_IP"
echo "  joplin.${DOMAIN_NAME} points to: $JOPLIN_IP"
echo "  camera.${DOMAIN_NAME} points to: $CAMERA_IP"
echo ""

if [ "$CURRENT_IP" != "$JOPLIN_IP" ] || [ "$CURRENT_IP" != "$CAMERA_IP" ]; then
    echo "⚠️  WARNING: Domains don't point to your current IP address!"
    echo "   Please update your DNS records to point to: $CURRENT_IP"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Please update DNS records first."
        exit 1
    fi
fi

# Start nginx with HTTP-only configuration first
echo "🚀 Starting nginx with HTTP-only configuration..."
cp nginx/nginx.conf nginx/nginx-backup.conf
cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name joplin.ritish.com.np camera.ritish.com.np;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            proxy_pass http://joplin:22300;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF

# Start services
docker compose up -d nginx

echo "⏳ Waiting for nginx to start..."
sleep 10

# Request SSL certificates
echo "🔑 Requesting SSL certificate for joplin.${DOMAIN_NAME}..."
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@${DOMAIN_NAME} \
    --agree-tos \
    --no-eff-email \
    -d joplin.${DOMAIN_NAME}

echo "🔑 Requesting SSL certificate for camera.${DOMAIN_NAME}..."
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@${DOMAIN_NAME} \
    --agree-tos \
    --no-eff-email \
    -d camera.${DOMAIN_NAME}

# Switch to HTTPS configuration
echo "🔄 Switching to HTTPS configuration..."
cp nginx/nginx-https.conf nginx/nginx.conf

# Restart nginx with HTTPS
echo "🔄 Restarting nginx with HTTPS..."
docker compose restart nginx

# Start automatic renewal
echo "🔄 Starting automatic certificate renewal..."
docker compose up -d certbot

echo ""
echo "✅ SSL setup complete!"
echo ""
echo "🌍 Your Joplin server is now available at:"
echo "   https://joplin.${DOMAIN_NAME}"
echo ""
echo "📹 Your camera system is available at:"
echo "   https://camera.${DOMAIN_NAME}"
echo ""
echo "🔐 SSL certificates will automatically renew every 12 hours."
echo ""
echo "📝 Next steps:"
echo "   1. Visit https://joplin.${DOMAIN_NAME} to set up your admin account"
echo "   2. Configure your Joplin clients to use: https://joplin.${DOMAIN_NAME}"
echo "   3. Test the camera system at: https://camera.${DOMAIN_NAME}"
