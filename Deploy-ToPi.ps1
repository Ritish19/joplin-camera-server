# PowerShell Script for Pi Deployment
# Run this script in PowerShell on Windows to deploy to your Raspberry Pi

param(
    [string]$PiIP = "192.168.1.150",
    [string]$PiUser = "pi"
)

Write-Host "🚀 Starting Joplin Server Deployment to Raspberry Pi" -ForegroundColor Green
Write-Host "Pi IP: $PiIP" -ForegroundColor Yellow

# Function to execute SSH commands
function Invoke-SSHCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "`n📋 $Description" -ForegroundColor Cyan
    Write-Host "Command: $Command" -ForegroundColor Gray
    
    $sshCommand = "ssh $PiUser@$PiIP `"$Command`""
    Write-Host "Executing: $sshCommand" -ForegroundColor Blue
    
    # Execute the command
    Invoke-Expression $sshCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Success" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Read-Host "Press Enter to continue or Ctrl+C to abort"
    }
}

Write-Host "`n🔍 Step 1: Finding and mounting the pendrive..." -ForegroundColor Yellow

# Check available drives
Invoke-SSHCommand "sudo fdisk -l | grep -E '^/dev/sd[a-z][0-9]'" "List available drives"

Write-Host "`n📝 Please identify your pendrive from the list above (e.g., /dev/sda1)"
$pendriveDevice = Read-Host "Enter the pendrive device path (e.g., /dev/sda1)"

if (-not $pendriveDevice) {
    $pendriveDevice = "/dev/sda1"
    Write-Host "Using default: $pendriveDevice" -ForegroundColor Yellow
}

# Create mount point and mount pendrive
Invoke-SSHCommand "sudo mkdir -p /mnt/pendrive" "Create mount point"
Invoke-SSHCommand "sudo mount $pendriveDevice /mnt/pendrive" "Mount pendrive"
Invoke-SSHCommand "sudo chown -R pi:pi /mnt/pendrive" "Set permissions for pendrive"

Write-Host "`n📁 Step 2: Setting up project directory..." -ForegroundColor Yellow

# Create project directory on pendrive
Invoke-SSHCommand "mkdir -p /mnt/pendrive/joplin-server" "Create project directory"
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && pwd" "Navigate to project directory"

Write-Host "`n📥 Step 3: Cloning repository..." -ForegroundColor Yellow

# Clone repository
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && git clone https://github.com/Ritish19/joplin-camera-server.git ." "Clone repository to pendrive"

Write-Host "`n⚙️ Step 4: Configuring environment..." -ForegroundColor Yellow

# Copy environment file
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && cp .env.example .env" "Copy environment template"

Write-Host "`n📝 Now you need to edit the .env file with your settings."
Write-Host "The script will open nano editor on the Pi. Please configure:"
Write-Host "- DOMAIN_NAME=ritish.com.np"
Write-Host "- POSTGRES_PASSWORD=your_secure_password"
Write-Host "- SMTP settings (if needed)"
Read-Host "Press Enter when ready to edit .env file"

Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && nano .env" "Edit environment configuration"

Write-Host "`n🔧 Step 5: Updating paths for pendrive..." -ForegroundColor Yellow

# Make scripts executable
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && chmod +x scripts/*.sh" "Make scripts executable"

# Update paths to use pendrive instead of USB
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && sed -i 's|/mnt/joplin-usb|/mnt/pendrive|g' docker-compose.yml" "Update docker-compose paths"
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && sed -i 's|/mnt/joplin-usb|/mnt/pendrive|g' scripts/deploy.sh" "Update deploy script paths"
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && sed -i 's|/mnt/joplin-usb|/mnt/pendrive|g' scripts/backup.sh" "Update backup script paths"

Write-Host "`n🚀 Step 6: Deploying services..." -ForegroundColor Yellow

# Deploy the system
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && ./scripts/deploy.sh" "Deploy Joplin server and camera system"

Write-Host "`n🔒 Step 7: Setting up SSL certificates..." -ForegroundColor Yellow

Write-Host "SSL setup will be interactive. Choose option 1 for self-signed certificates (testing) or option 2 for Let's Encrypt (production)"
Read-Host "Press Enter to start SSL setup"

Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && ./scripts/setup-ssl.sh" "Setup SSL certificates"

Write-Host "`n📊 Step 8: Checking deployment status..." -ForegroundColor Yellow

# Check service status
Invoke-SSHCommand "cd /mnt/pendrive/joplin-server && docker-compose ps" "Check service status"

Write-Host "`n🎉 Deployment completed!" -ForegroundColor Green
Write-Host "`n📋 Useful commands:" -ForegroundColor Yellow
Write-Host "View logs: ssh $PiUser@$PiIP 'cd /mnt/pendrive/joplin-server && docker-compose logs -f'" -ForegroundColor Gray
Write-Host "Restart services: ssh $PiUser@$PiIP 'cd /mnt/pendrive/joplin-server && docker-compose restart'" -ForegroundColor Gray
Write-Host "Create backup: ssh $PiUser@$PiIP 'cd /mnt/pendrive/joplin-server && ./scripts/backup.sh'" -ForegroundColor Gray

Write-Host "`n🌐 Access your services:" -ForegroundColor Yellow
Write-Host "Joplin Server: https://joplin.ritish.com.np" -ForegroundColor Green
Write-Host "Camera System: https://camera.ritish.com.np" -ForegroundColor Green

Write-Host "`n✅ Deployment script completed!" -ForegroundColor Green
