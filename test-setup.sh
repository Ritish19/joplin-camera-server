#!/bin/bash

# Test script to verify Joplin server is working properly

set -e

echo "🧪 Testing Joplin Server Setup..."
echo "=================================="

# Test 1: Check if Docker is running
echo "1. Checking Docker service..."
if systemctl is-active --quiet docker; then
    echo "   ✅ Docker is running"
else
    echo "   ❌ Docker is not running"
    exit 1
fi

# Test 2: Check if containers are running
echo ""
echo "2. Checking container status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test 3: Check if Joplin server is responding
echo ""
echo "3. Testing Joplin server response..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:22300 | grep -q "200\|302\|401"; then
    echo "   ✅ Joplin server is responding"
else
    echo "   ❌ Joplin server is not responding"
    echo "   Checking logs..."
    docker logs joplin-server --tail 10
fi

# Test 4: Check database connection
echo ""
echo "4. Testing database connection..."
if docker exec joplin-postgres pg_isready -U joplin_user > /dev/null 2>&1; then
    echo "   ✅ Database is ready"
else
    echo "   ❌ Database connection failed"
fi

# Test 5: Check systemd service status
echo ""
echo "5. Checking systemd service status..."
if systemctl is-active --quiet joplin-server 2>/dev/null; then
    echo "   ✅ Joplin service is active"
else
    echo "   ⚠️  Joplin systemd service not found (run setup-autostart.sh first)"
fi

# Test 6: Check local network access
echo ""
echo "6. Testing local network access..."
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "   Local IP: $LOCAL_IP"
echo "   Local URL: http://$LOCAL_IP:22300"

# Test 7: Check storage paths
echo ""
echo "7. Checking storage paths..."
if [ -d "/media/pi/joplin-server" ]; then
    echo "   ✅ Pendrive mounted at /media/pi/joplin-server"
    echo "   Storage usage:"
    df -h /media/pi/joplin-server
else
    echo "   ❌ Pendrive not mounted at /media/pi/joplin-server"
fi

echo ""
echo "🎯 Test Summary:"
echo "=================="
echo "✅ Local access:     http://$LOCAL_IP:22300"
echo "⏳ Internet access:  https://joplin.ritish.com.np (waiting for DNS)"
echo "📱 Camera system:    http://$LOCAL_IP:8765"
echo ""
echo "Test complete! 🚀"
