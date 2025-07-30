#!/bin/bash

# Create systemd service for auto-starting Joplin server
# This script sets up the Joplin server to start automatically on Pi boot

set -e

echo "🚀 Setting up Joplin Server autostart service..."

# Create systemd service file
sudo tee /etc/systemd/system/joplin-server.service > /dev/null <<EOF
[Unit]
Description=Joplin Server with Camera System
Requires=docker.service
After=docker.service
StartLimitIntervalSec=0

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/media/pi/joplin-server
ExecStartPre=/usr/bin/docker-compose down
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0
User=pi
Group=pi

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Systemd service file created"

# Reload systemd daemon
echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "🔧 Enabling Joplin server autostart..."
sudo systemctl enable joplin-server.service

# Start the service now
echo "🚀 Starting Joplin server service..."
sudo systemctl start joplin-server.service

# Check service status
echo "📊 Service status:"
sudo systemctl status joplin-server.service --no-pager

echo ""
echo "🎉 Joplin Server autostart setup complete!"
echo ""
echo "Service commands:"
echo "  Start:   sudo systemctl start joplin-server"
echo "  Stop:    sudo systemctl stop joplin-server"
echo "  Restart: sudo systemctl restart joplin-server"
echo "  Status:  sudo systemctl status joplin-server"
echo "  Logs:    journalctl -u joplin-server -f"
echo ""
echo "The service will now automatically start when the Pi boots up!"
