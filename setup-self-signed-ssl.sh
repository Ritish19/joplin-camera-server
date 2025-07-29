#!/bin/bash

# Self-Signed SSL Certificate Setup for Local HTTPS Testing
# This creates certificates that will show browser warnings but enable HTTPS

set -e

echo "🔐 Setting up Self-Signed SSL certificates for local testing..."

# Create SSL directory
mkdir -p ./nginx/ssl

# Generate private key
echo "🔑 Generating private key..."
openssl genrsa -out ./nginx/ssl/server.key 4096

# Generate certificate signing request
echo "📝 Generating certificate signing request..."
openssl req -new -key ./nginx/ssl/server.key -out ./nginx/ssl/server.csr -subj "/C=NP/ST=Bagmati/L=Kathmandu/O=Joplin Server/CN=192.168.1.150"

# Generate self-signed certificate
echo "📜 Generating self-signed certificate..."
openssl x509 -req -days 365 -in ./nginx/ssl/server.csr -signkey ./nginx/ssl/server.key -out ./nginx/ssl/server.crt

# Create nginx configuration for self-signed SSL
echo "📄 Creating nginx configuration for self-signed SSL..."
cat > ./nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    
    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name _;
        return 301 https://$server_name$request_uri;
    }
    
    # HTTPS Joplin Server
    server {
        listen 443 ssl;
        server_name _;
        
        # Self-signed SSL certificates
        ssl_certificate /etc/nginx/ssl/server.crt;
        ssl_certificate_key /etc/nginx/ssl/server.key;
        
        # SSL settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        
        # Large file upload support
        client_max_body_size 100M;
        
        # Proxy to Joplin Server
        location / {
            proxy_pass http://joplin:22300;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
EOF

echo "✅ Self-signed SSL setup complete!"
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "   - Browsers will show security warnings (this is normal for self-signed certificates)"
echo "   - Click 'Advanced' → 'Proceed to 192.168.1.150 (unsafe)' to continue"
echo "   - This is safe for local testing but not recommended for production"
echo ""
echo "🌐 Your Joplin server will be available at:"
echo "   https://192.168.1.150 (with browser security warning)"
echo ""
echo "📝 To use this configuration:"
echo "   1. Run: docker compose down"
echo "   2. Run: docker compose up -d"
echo "   3. Visit: https://192.168.1.150"
