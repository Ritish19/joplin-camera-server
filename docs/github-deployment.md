# GitHub Repository Setup & Pi Deployment Guide

This guide will help you set up this project as a GitHub repository and establish a workflow to deploy updates to your Raspberry Pi.

## Part 1: Create GitHub Repository

### 1.1 Initialize Git Repository (on Windows)

Open PowerShell in your project directory and run:

```powershell
# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Complete Joplin & Camera Server setup"
```

### 1.2 Create GitHub Repository

1. Go to [GitHub.com](https://github.com) and sign in
2. Click "New repository" or go to https://github.com/new
3. Repository name: `joplin-camera-server` (or your preferred name)
4. Description: `Self-hosted Joplin notes server with camera monitoring system for Raspberry Pi`
5. Make it **Public** (so your Pi can access it easily) or **Private** (if you prefer)
6. **Don't** initialize with README, .gitignore, or license (we already have these)
7. Click "Create repository"

### 1.3 Connect Local Repository to GitHub

Replace `yourusername` with your actual GitHub username:

```powershell
# Add GitHub remote
git remote add origin https://github.com/yourusername/joplin-camera-server.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Part 2: Deploy to Raspberry Pi

### 2.1 Prepare Raspberry Pi

SSH into your Raspberry Pi:

```bash
ssh pi@192.168.1.150
```

Make sure git is installed:
```bash
sudo apt update
sudo apt install -y git
```

### 2.2 Clone Repository on Pi

```bash
# Navigate to home directory
cd /home/pi

# Clone your repository (replace with your actual GitHub URL)
git clone https://github.com/yourusername/joplin-camera-server.git

# Enter project directory
cd joplin-camera-server
```

### 2.3 Initial Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit configuration file
nano .env
```

Update `.env` with your actual values:
```bash
DOMAIN_NAME=ritish.com.np
POSTGRES_PASSWORD=your_secure_password_here
SMTP_HOST=smtp.gmail.com
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
# ... etc
```

### 2.4 Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### 2.5 Deploy the System

```bash
# Run the deployment script
./scripts/deploy.sh
```

This will:
- Create required directories
- Pull Docker images
- Start all services
- Check service health

### 2.6 Set Up SSL Certificates

```bash
# Run SSL setup
./scripts/setup-ssl.sh
```

Choose your preferred SSL option (Let's Encrypt recommended for production).

## Part 3: Establish Update Workflow

### 3.1 Making Changes from Windows

When you want to update the Pi configuration:

1. Make changes to files in Windows
2. Commit and push to GitHub:

```powershell
# Add changes
git add .

# Commit with descriptive message
git commit -m "Update nginx configuration for better security"

# Push to GitHub
git push origin main
```

### 3.2 Updating Pi from GitHub

On your Raspberry Pi, run:

```bash
# Navigate to project directory
cd /home/pi/joplin-camera-server

# Pull latest changes and update system
./scripts/update.sh
```

The update script will:
- Create a backup before updating
- Pull latest changes from GitHub
- Restart services if needed
- Show any errors or status updates

## Part 4: Useful Commands

### On Windows (Development)

```powershell
# Check status
git status

# View changes
git diff

# Push changes
git add .; git commit -m "Your commit message"; git push

# View commit history
git log --oneline
```

### On Raspberry Pi (Production)

```bash
# Check system status
cd /home/pi/joplin-camera-server
docker-compose ps

# View logs
docker-compose logs -f

# Update from GitHub
./scripts/update.sh

# Manual backup
./scripts/backup.sh

# Restart specific service
docker-compose restart joplin

# Check resource usage
docker stats
```

## Part 5: Advanced Workflow

### 5.1 Branching Strategy

For safer deployments, consider using branches:

```powershell
# On Windows - create development branch
git checkout -b development

# Make changes and test locally
git add .; git commit -m "Test new feature"

# Push development branch
git push origin development

# When ready, merge to main
git checkout main
git merge development
git push origin main
```

### 5.2 Automated Deployment (Optional)

You can set up automatic updates on Pi using cron:

```bash
# Edit crontab
crontab -e

# Add automatic update check (every 6 hours)
0 */6 * * * cd /home/pi/joplin-camera-server && git fetch && git diff HEAD origin/main --quiet || ./scripts/update.sh >> /var/log/auto-update.log 2>&1
```

### 5.3 Monitoring and Alerts

Set up a monitoring script:

```bash
# Create monitoring script
cat > /home/pi/check-services.sh << 'EOF'
#!/bin/bash
cd /home/pi/joplin-camera-server
if ! docker-compose ps | grep -q "Up"; then
    echo "Service down detected at $(date)" >> /var/log/service-monitor.log
    # Send email or notification here if configured
fi
EOF

chmod +x /home/pi/check-services.sh

# Add to crontab (check every 5 minutes)
echo "*/5 * * * * /home/pi/check-services.sh" | crontab -
```

## Part 6: Troubleshooting

### Common Issues

1. **Git authentication issues**
   ```bash
   # Use personal access token instead of password
   git clone https://username:token@github.com/username/repo.git
   ```

2. **Permission issues on Pi**
   ```bash
   sudo chown -R pi:pi /home/pi/joplin-camera-server
   ```

3. **Network connectivity issues**
   ```bash
   # Test internet connectivity
   ping -c 4 github.com
   ```

4. **Docker issues**
   ```bash
   # Restart Docker
   sudo systemctl restart docker
   
   # Check Docker status
   sudo systemctl status docker
   ```

### Getting Help

1. Check repository issues on GitHub
2. Review service logs: `docker-compose logs [service-name]`
3. Check system logs: `journalctl -f`
4. Monitor resource usage: `htop` or `docker stats`

## Summary

You now have:
- ✅ Complete project structure in GitHub
- ✅ Easy deployment to Raspberry Pi
- ✅ Update workflow using Git
- ✅ Automated backup and maintenance scripts
- ✅ SSL certificate management
- ✅ Security configurations

Your Joplin server and camera system can now be easily maintained and updated through GitHub!
