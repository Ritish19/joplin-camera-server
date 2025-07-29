# Joplin Server & Camera System

A complete self-hosted solution for secure note synchronization and camera monitoring on Raspberry Pi, accessible via custom domain subdomains.

## 🚀 Quick Start

### Prerequisites
- Raspberry Pi with Docker and Docker Compose installed
- Custom domain (e.g., ritish.com.np)
- Cloudflare account for tunnel setup
- USB storage mounted at `/mnt/joplin-usb/`

### Deployment
1. Clone this repository on your Raspberry Pi:
   ```bash
   git clone https://github.com/yourusername/joplin-camera-server.git
   cd joplin-camera-server
   ```

2. Copy environment template and configure:
   ```bash
   cp .env.example .env
   nano .env
   ```

3. Deploy the services:
   ```bash
   ./scripts/deploy.sh
   ```

## 📁 Project Structure

```
├── docker-compose.yml          # Main orchestration file
├── .env.example               # Environment variables template
├── nginx/                     # Nginx reverse proxy configuration
│   ├── nginx.conf
│   ├── sites-available/
│   └── ssl/
├── scripts/                   # Deployment and maintenance scripts
│   ├── deploy.sh
│   ├── backup.sh
│   └── update.sh
├── config/                    # Service configurations
│   ├── joplin/
│   ├── motioneye/
│   └── fail2ban/
└── docs/                      # Detailed documentation
```

## 🌐 Services

- **Joplin Server**: `joplin.ritish.com.np` - Secure note synchronization
- **Camera System**: `camera.ritish.com.np` - MotionEye monitoring
- **Database**: PostgreSQL for reliable data storage
- **Reverse Proxy**: Nginx with SSL/TLS termination

## 🔒 Security Features

- Docker container isolation
- SSL/TLS encryption via Let's Encrypt
- Fail2ban intrusion detection
- Strong authentication with 2FA capability
- Regular automated backups

## 📖 Documentation

See the [docs](./docs/) directory for detailed documentation:
- [Installation Guide](./docs/installation.md)
- [Configuration Reference](./docs/configuration.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [Project History](./docs/project-history.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on your Pi
5. Submit a pull request

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.
