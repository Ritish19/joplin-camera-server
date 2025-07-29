# Installation Guide

This guide will walk you through the complete installation process of the Joplin Server & Camera System on your Raspberry Pi.

## Prerequisites

### Hardware Requirements
- Raspberry Pi 4 (recommended) or Pi 3B+
- MicroSD card (32GB+ recommended)
- USB storage device for persistent data
- USB camera or Pi Camera module
- Stable internet connection

### Software Requirements
- Raspberry Pi OS (64-bit recommended)
- Docker and Docker Compose
- Git
- Domain name with DNS control

### Network Requirements
- Access to router configuration (for local setup)
- Cloudflare account (for internet access through CGNAT)

## Step 1: Prepare Raspberry Pi

### 1.1 Install Raspberry Pi OS
1. Download and flash Raspberry Pi OS to your SD card
2. Enable SSH and set up WiFi during imaging
3. Boot the Pi and complete initial setup

### 1.2 Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### 1.3 Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install -y docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### 1.4 Prepare USB Storage
```bash
# Create mount point
sudo mkdir -p /mnt/joplin-usb

# Format USB drive (replace /dev/sda1 with your USB device)
sudo mkfs.ext4 /dev/sda1

# Get UUID for permanent mounting
sudo blkid /dev/sda1

# Add to fstab for permanent mounting
echo "UUID=your-uuid-here /mnt/joplin-usb ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

# Mount the drive
sudo mount -a

# Set permissions
sudo chown -R $USER:$USER /mnt/joplin-usb
```

## Step 2: Domain and DNS Setup

### 2.1 Domain Configuration
1. Purchase a domain (e.g., ritish.com.np)
2. Set up DNS records:
   - A record: `joplin.yourdomain.com` → Your Cloudflare Tunnel IP
   - A record: `camera.yourdomain.com` → Your Cloudflare Tunnel IP

### 2.2 Cloudflare Tunnel Setup
1. Install cloudflared on Pi:
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared-linux-arm64.deb
```

2. Authenticate with Cloudflare:
```bash
cloudflared tunnel login
```

3. Create tunnel:
```bash
cloudflared tunnel create joplin-server
cloudflared tunnel route dns joplin-server joplin.yourdomain.com
cloudflared tunnel route dns joplin-server camera.yourdomain.com
```

4. Configure tunnel (create `~/.cloudflared/config.yml`):
```yaml
tunnel: your-tunnel-id
credentials-file: /home/pi/.cloudflared/your-tunnel-id.json

ingress:
  - hostname: joplin.yourdomain.com
    service: http://localhost:80
    originRequest:
      httpHostHeader: joplin.yourdomain.com
  - hostname: camera.yourdomain.com
    service: http://localhost:80
    originRequest:
      httpHostHeader: camera.yourdomain.com
  - service: http_status:404
```

5. Install tunnel as service:
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

## Step 3: Deploy the Application

### 3.1 Clone Repository
```bash
cd /home/pi
git clone https://github.com/yourusername/joplin-camera-server.git
cd joplin-camera-server
```

### 3.2 Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

Update the following values in `.env`:
```bash
DOMAIN_NAME=yourdomain.com
POSTGRES_PASSWORD=your_secure_password
SMTP_HOST=your_smtp_server
SMTP_USER=your_email
SMTP_PASSWORD=your_app_password
```

### 3.3 Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### 3.4 Deploy Services
```bash
./scripts/deploy.sh
```

This script will:
- Create required directories
- Pull Docker images
- Start all services
- Check service health

## Step 4: SSL Certificate Setup

### 4.1 Run SSL Setup Script
```bash
./scripts/setup-ssl.sh
```

Choose option 2 for Let's Encrypt certificates (recommended for production).

### 4.2 Verify SSL Configuration
```bash
# Check certificate status
sudo certbot certificates

# Test automatic renewal
sudo certbot renew --dry-run
```

## Step 5: Configure Services

### 5.1 Joplin Server Setup
1. Access https://joplin.yourdomain.com
2. Create admin account
3. Configure server settings
4. Test synchronization with Joplin client

### 5.2 Camera System Setup
1. Access https://camera.yourdomain.com
2. Use credentials set during SSL setup
3. Add camera devices
4. Configure recording settings
5. Set up motion detection

## Step 6: Security Configuration

### 6.1 Verify Fail2ban
```bash
# Check Fail2ban status
docker-compose exec fail2ban fail2ban-client status

# View active jails
docker-compose exec fail2ban fail2ban-client status --all
```

### 6.2 Test Security
- Attempt failed logins to verify fail2ban blocking
- Check SSL certificate validity
- Verify HTTPS redirects

## Step 7: Backup Setup

### 7.1 Test Backup System
```bash
./scripts/backup.sh
```

### 7.2 Schedule Automatic Backups
```bash
# Edit crontab
crontab -e

# Add backup schedule (daily at 2 AM)
0 2 * * * cd /home/pi/joplin-camera-server && ./scripts/backup.sh >> /var/log/joplin-backup.log 2>&1
```

## Step 8: Monitoring and Maintenance

### 8.1 Monitor Services
```bash
# Check all services
docker-compose ps

# View logs
docker-compose logs -f

# Check resource usage
docker stats
```

### 8.2 Regular Maintenance
```bash
# Update system
./scripts/update.sh

# Clean up old images
docker system prune -f

# Check disk usage
df -h /mnt/joplin-usb
```

## Troubleshooting

### Common Issues

1. **Services won't start**
   ```bash
   # Check logs
   docker-compose logs [service-name]
   
   # Restart specific service
   docker-compose restart [service-name]
   ```

2. **SSL certificate issues**
   ```bash
   # Regenerate certificates
   ./scripts/setup-ssl.sh
   ```

3. **Permission issues**
   ```bash
   # Fix USB mount permissions
   sudo chown -R $USER:$USER /mnt/joplin-usb
   ```

4. **Database connection issues**
   ```bash
   # Reset database
   docker-compose down
   sudo rm -rf /mnt/joplin-usb/postgres-data
   docker-compose up -d
   ```

### Getting Help

1. Check service logs: `docker-compose logs [service]`
2. Verify configuration files
3. Check network connectivity
4. Review firewall settings
5. Consult project documentation

## Next Steps

After successful installation:
1. Configure Joplin clients to sync with your server
2. Set up mobile access to camera system
3. Configure backup storage (cloud sync)
4. Set up monitoring alerts
5. Plan regular maintenance schedule

Your Joplin Server & Camera System should now be fully operational!
