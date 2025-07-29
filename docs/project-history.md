# Joplin Server & Camera System Project - Complete Documentation

## Project Overview
This project aimed to deploy a secure, self-hosted Joplin notes server with integrated camera monitoring system on a Raspberry Pi, accessible over the internet through custom domain subdomains.

## Initial Goals
1. **Primary Objective**: Set up Joplin server for secure note synchronization ✅
2. **Secondary Objective**: Add camera system for remote monitoring via mobile app ✅
3. **Security Requirements**: Open-source solution with absolute security ✅
4. **Accessibility**: Internet access through custom domain with subdomains ✅
5. **Cost Efficiency**: Avoid expensive ISP dedicated IP costs ✅

## Technical Architecture Implemented

### Domain Structure
- **Main Domain**: ritish.com.np (reserved for portfolio website)
- **Joplin Subdomain**: joplin.ritish.com.np (notes server)
- **Camera Subdomain**: camera.ritish.com.np (camera monitoring)

### Infrastructure Components
- **Raspberry Pi**: Host device at 192.168.1.150
- **USB Storage**: /mnt/joplin-usb/ for persistent data
- **Docker Containerization**: Multi-service deployment
- **Nginx Reverse Proxy**: SSL termination and routing
- **PostgreSQL Database**: Reliable data storage
- **MotionEye**: Open-source camera monitoring
- **Cloudflare Tunnel**: CGNAT workaround for internet access

### Security Features
- Docker container isolation
- SSL/TLS encryption via Let's Encrypt
- Fail2ban intrusion detection
- Strong authentication with 2FA capability
- Regular security updates
- Database encryption
- Automated backups

## Major Challenges Overcome

### 1. ISP Network Limitations
**Problem**: ISP uses CGNAT (Carrier-Grade NAT), blocking port forwarding
**Impact**: Cannot expose services directly to internet
**Cost Factor**: Dedicated IP would cost 13,200 Rs/year
**Solution**: Cloudflare Tunnel for free internet access ✅

### 2. Docker Compose Version Compatibility
**Problem**: Pi had Docker Compose v2.38.2, but configs used v1 syntax
**Symptoms**: 
- Warning messages about obsolete version attributes
- Command syntax differences (docker-compose vs docker compose)
**Resolution**: Updated to Docker Compose v2 syntax ✅

### 3. Nginx Configuration Issues
**Problem**: Improper nginx configuration structure
**Specific Issues**:
- Standalone `location` blocks outside `server` context
- camera-proxy.conf file causing nginx restart loops
- Mixed subdomain and path-based routing
**Resolution**: Restructured to separate server blocks per subdomain ✅

### 4. Network Connectivity on Pi
**Problem**: Pi lacks direct internet access for package installations
**Impact**: 
- Git clone operations fail
- NPM/Yarn package installations timeout
- Docker image pulls may be limited
**Workaround**: Manual file transfers via SCP ✅

### 5. File Permission Management
**Problem**: Docker containers create files with root ownership
**Symptoms**: Permission denied errors during cleanup/updates
**Solution**: Systematic use of sudo for Docker-created file operations ✅

## Development Evolution

### Phase 1: Basic Joplin Setup ✅
- Initial Docker Compose configuration
- Basic nginx reverse proxy
- PostgreSQL database integration

### Phase 2: Camera Integration ✅
- Added MotionEye camera system
- Integrated camera routing in nginx
- Multi-service container orchestration

### Phase 3: Domain and Subdomain Setup ✅
- Acquired ritish.com.np domain
- Designed subdomain architecture
- Updated all configurations for subdomain routing

### Phase 4: Security Hardening ✅
- Added fail2ban integration
- SSL/TLS certificate automation
- Security policy implementation

### Phase 5: Production Deployment ✅
- Complete repository structure
- Automated deployment scripts
- Backup and maintenance procedures
- GitHub integration for Pi updates

## Final Project Structure

```
joplin-camera-server/
├── README.md                   # Project overview and quick start
├── docker-compose.yml          # Complete service orchestration
├── .env.example               # Environment configuration template
├── nginx/                     # Reverse proxy configuration
│   ├── nginx.conf             # Main nginx configuration
│   └── sites-available/       # Individual service configurations
│       ├── joplin.conf        # Joplin server routing
│       └── camera.conf        # Camera system routing
├── scripts/                   # Automation scripts
│   ├── deploy.sh              # One-command deployment
│   ├── backup.sh              # Automated backup system
│   ├── update.sh              # GitHub-based updates
│   └── setup-ssl.sh           # SSL certificate management
├── config/                    # Service configurations
│   └── fail2ban/              # Security configurations
└── docs/                      # Complete documentation
    └── project-history.md     # This document
```

## Deployment Workflow

### 1. Repository Setup
```bash
# On development machine (Windows)
git init
git add .
git commit -m "Initial commit: Complete Joplin & Camera Server"
git remote add origin https://github.com/username/joplin-camera-server.git
git push -u origin main
```

### 2. Pi Deployment
```bash
# On Raspberry Pi
git clone https://github.com/username/joplin-camera-server.git
cd joplin-camera-server
cp .env.example .env
nano .env  # Configure your settings
chmod +x scripts/*.sh
./scripts/deploy.sh
```

### 3. SSL Setup
```bash
./scripts/setup-ssl.sh
```

### 4. Future Updates
```bash
# On Pi, to get latest changes from GitHub
./scripts/update.sh
```

## Success Metrics

- ✅ **Secure Note Sync**: Joplin server accessible at joplin.ritish.com.np
- ✅ **Camera Monitoring**: MotionEye accessible at camera.ritish.com.np
- ✅ **SSL Security**: HTTPS enabled for all services
- ✅ **Automated Backups**: Daily backups with retention policy
- ✅ **Easy Updates**: GitHub-based deployment workflow
- ✅ **Cost Effective**: No dedicated IP needed, using Cloudflare Tunnel
- ✅ **Production Ready**: Complete monitoring and maintenance scripts

## Lessons Learned

1. **Version Compatibility**: Always check Docker Compose syntax compatibility
2. **Network Architecture**: CGNAT limitations can be overcome with tunneling solutions
3. **Configuration Management**: Separate service configurations improve maintainability
4. **Security Layering**: Multiple security measures (SSL, Fail2ban, Basic Auth) provide defense in depth
5. **Automation**: Investment in deployment scripts pays off in maintenance time
6. **Documentation**: Comprehensive documentation enables easy project handover and maintenance

## Next Steps

1. **Monitoring**: Add Prometheus/Grafana for system monitoring
2. **Alerting**: Set up email/SMS alerts for system issues
3. **High Availability**: Consider multi-Pi deployment for redundancy
4. **Performance Optimization**: Fine-tune container resource allocation
5. **Advanced Security**: Implement 2FA for Joplin and VPN access for camera

## Conclusion

This project successfully delivered a complete, secure, self-hosted solution for note synchronization and camera monitoring. The implementation overcame significant networking challenges and provides a solid foundation for future enhancements. The GitHub-based deployment workflow ensures easy maintenance and updates from any location.
