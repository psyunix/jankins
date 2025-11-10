# 🚀 Jankins - Jenkins CI/CD with Docker & GitHub Actions

A complete Jenkins CI/CD setup with automated deployment using GitHub Actions, Docker, and a test web server environment.

[![CI/CD Pipeline](https://github.com/psyunix/jankins/actions/workflows/ci.yml/badge.svg)](https://github.com/psyunix/jankins/actions/workflows/ci.yml)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Manual Setup](#manual-setup)
- [Services](#services)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This project provides a production-ready Jenkins CI/CD environment with:
- **Jenkins LTS** - Latest Long-Term Support version running in Docker
- **Web Server** - Apache + MariaDB + PHP test environment
- **GitHub Actions** - Automated testing and deployment pipeline
- **Docker Compose** - Easy orchestration of all services
- **Quick Start Script** - One-command deployment

## ✨ Features

- 🐳 **Fully Dockerized** - All services run in isolated containers
- � **Pre-built Images** - Pull from GitHub Container Registry (GHCR) for instant deployment
- �🔄 **Automated CI/CD** - GitHub Actions workflow for testing and image building
- 🌐 **Test Web Server** - Apache with PHP and MariaDB for integration testing
- 📊 **Health Checks** - Automated service monitoring
- 🔧 **Easy Configuration** - Simple docker-compose setup
- 🚀 **One-Command Deploy** - Quick start script for instant setup
- 📝 **Comprehensive Logging** - Full visibility into all services

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     GitHub Actions                       │
│  (Automated Build, Test & Deploy on Push)               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│                   Docker Compose                         │
│  ┌──────────────────┐        ┌──────────────────┐      │
│  │    Jenkins LTS    │        │   Web Server     │      │
│  │   Port: 8080     │◄──────►│   Port: 8081     │      │
│  │                  │        │                  │      │
│  │  - CI/CD Engine  │        │  - Apache        │      │
│  │  - Build Jobs    │        │  - MariaDB       │      │
│  │  - Plugins       │        │  - PHP 8.1       │      │
│  │                  │        │  - Test App      │      │
│  └──────────────────┘        └──────────────────┘      │
│           │                           │                 │
│           ↓                           ↓                 │
│    jenkins_home/               webserver/              │
│    (persistent)                (source files)          │
└─────────────────────────────────────────────────────────┘
```

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Desktop** (v20.10 or higher)
  - [Download for Mac](https://www.docker.com/products/docker-desktop/)
  - [Download for Windows](https://www.docker.com/products/docker-desktop/)
  - [Download for Linux](https://docs.docker.com/desktop/install/linux-install/)
- **Docker Compose** (v2.0 or higher, usually included with Docker Desktop)
- **Git** (for cloning the repository)

### Verify Installation

```bash
docker --version
docker-compose --version
```

## 🚀 Quick Start

### Option A: Use Pre-built Images (Fastest! ⚡)

No need to build Docker images locally - use our pre-built images from GitHub Container Registry:

```bash
git clone https://github.com/psyunix/jankins.git
cd jankins
chmod +x pull-and-run.sh
./pull-and-run.sh
```

📖 [Read more about pre-built images](GHCR_USAGE.md)

### Option B: Build Locally

The traditional way - build Docker images on your machine:

#### 1. Clone the Repository

```bash
git clone https://github.com/psyunix/jankins.git
cd jankins
```

#### 2. Run the Quick Start Script

```bash
chmod +x quickstart.sh
./quickstart.sh
```

This script will:
- ✅ Check Docker installation
- ✅ Build all Docker images
- ✅ Start all services
- ✅ Wait for services to be ready
- ✅ Display access URLs and credentials
- ✅ Open services in your browser

### 3. Access Your Services

- **Jenkins:** http://localhost:8080
- **Web Server:** http://localhost:8081

The initial Jenkins admin password will be displayed in the terminal output.

## 🔧 Manual Setup

If you prefer to run commands manually:

### Build Images

```bash
docker-compose build
```

### Start Services

```bash
docker-compose up -d
```

### Check Status

```bash
docker-compose ps
```

### View Logs

```bash
# All services
docker-compose logs -f

# Jenkins only
docker-compose logs -f jenkins

# Web server only
docker-compose logs -f webserver
```

### Stop Services

```bash
docker-compose down
```

### Stop and Remove Volumes

```bash
docker-compose down -v
```

## 🌐 Services

### Jenkins (Port 8080)

**Features:**
- Latest Jenkins LTS version
- Docker CLI installed inside container
- Persistent storage for configuration and jobs
- Pre-configured for CI/CD workflows

**Initial Setup:**
1. Access http://localhost:8080
2. Get the initial admin password:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Install suggested plugins
4. Create your first admin user

### Web Server (Port 8081)

**Features:**
- Ubuntu 22.04 base
- Apache 2.4
- PHP 8.1 with MySQL support
- MariaDB database server
- Pre-configured test application

**Test Pages:**
- **Home:** http://localhost:8081 - Server information and PHP details
- **Database Test:** http://localhost:8081/db-test.php - MariaDB connection test

**Database Credentials:**
- **Host:** localhost
- **Database:** testdb
- **Username:** testuser
- **Password:** testpass123

## ⚙️ GitHub Actions CI/CD

This project includes a complete CI/CD pipeline that automatically:

### Workflow Triggers

- Push to `main` or `master` branch
- Pull requests to `main` or `master` branch
- Manual trigger via GitHub Actions UI

### Workflows

#### 1. Testing Pipeline (ci.yml)

**Automated Testing:**
1. **Checkout Code** - Clones the repository
2. **Set up Docker Buildx** - Prepares multi-platform builds
3. **Build Jenkins Image** - Builds custom Jenkins container
4. **Build Web Server Image** - Builds LAMP stack container
5. **Start Services** - Launches all containers with docker-compose
6. **Health Checks** - Verifies Jenkins and Web Server are running
7. **Content Tests** - Validates web server responses
8. **Log Collection** - Captures logs for debugging
9. **Cleanup** - Removes containers and volumes

#### 2. Build and Push Images (build-images.yml)

**Automated Image Publishing:**
1. **Build Docker Images** - Builds both Jenkins and Web Server images
2. **Push to GHCR** - Publishes to GitHub Container Registry
3. **Multi-tagging** - Tags with latest, main, version, and commit SHA
4. **Layer Caching** - Optimizes build times

**Published Images:**
- `ghcr.io/psyunix/jankins/jenkins:latest`
- `ghcr.io/psyunix/jankins/webserver:latest`

### View Workflow Results

Visit: https://github.com/psyunix/jankins/actions

### View Published Images

Visit: https://github.com/psyunix?tab=packages

## 🧪 Testing

### Local Testing

Test services manually:

```bash
# Test Jenkins
curl http://localhost:8080/login

# Test Web Server
curl http://localhost:8081

# Test Database Connection
curl http://localhost:8081/db-test.php
```

### Automated Testing

The GitHub Actions workflow runs automatically on every push and includes:

- Service health checks
- HTTP response validation
- Content verification
- Database connectivity tests

## 🔍 Troubleshooting

### Services won't start

```bash
# Check Docker is running
docker info

# Check for port conflicts
lsof -i :8080  # Jenkins
lsof -i :8081  # Web Server

# Check logs
docker-compose logs
```

### Jenkins is slow to start

Jenkins typically takes 1-2 minutes to fully initialize. Check progress:

```bash
docker-compose logs -f jenkins
```

### Can't access web server

```bash
# Verify container is running
docker-compose ps

# Check web server logs
docker-compose logs webserver

# Restart the service
docker-compose restart webserver
```

### Database connection fails

```bash
# Access the container
docker exec -it webserver bash

# Check MariaDB status
service mariadb status

# Test connection manually
mysql -u testuser -p testdb
# Password: testpass123
```

### Reset everything

```bash
# Stop and remove everything
docker-compose down -v

# Remove Docker images
docker rmi jenkins-custom webserver-custom

# Start fresh
./quickstart.sh
```

## 📁 Project Structure

```
jankins/
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions workflow
├── webserver/
│   ├── index.php               # Main test page
│   ├── db-test.php             # Database test page
│   ├── init-db.sh              # Database initialization script
│   └── start.sh                # Container startup script
├── Dockerfile.jenkins          # Jenkins container definition
├── Dockerfile.webserver        # Web server container definition
├── docker-compose.yml          # Service orchestration (local build)
├── docker-compose.ghcr.yml     # Service orchestration (pre-built images)
├── quickstart.sh               # Quick start deployment script
├── pull-and-run.sh             # Pull pre-built images and run
├── GHCR_USAGE.md               # Guide for using pre-built images
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## 🔒 Security Notes

**⚠️ This is a development/testing environment. For production:**

- Change default database credentials
- Use environment variables for secrets
- Enable HTTPS/TLS
- Configure Jenkins security properly
- Use Docker secrets for sensitive data
- Implement proper network isolation
- Enable firewall rules
- Regular security updates

## 🛠️ Customization

### Modify Jenkins Configuration

Edit `Dockerfile.jenkins`:
```dockerfile
# Add plugins
RUN jenkins-plugin-cli --plugins "plugin-name:version"

# Add custom configuration
COPY jenkins.yaml /var/jenkins_home/
```

### Modify Web Server

Edit `Dockerfile.webserver` to add additional packages or modify `webserver/` files to change the test application.

### Environment Variables

Create a `.env` file:
```env
JENKINS_PORT=8080
WEBSERVER_PORT=8081
MYSQL_ROOT_PASSWORD=yourpassword
```

Update `docker-compose.yml` to use these variables.

## 📊 Monitoring

### Check Resource Usage

```bash
docker stats
```

### View Container Details

```bash
docker inspect jenkins
docker inspect webserver
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## � Documentation

- 📖 **[GHCR Usage Guide](GHCR_USAGE.md)** - Using pre-built Docker images
- 🔧 **[Jenkins Jobs Tutorial](JENKINS_JOBS_TUTORIAL.md)** - Creating jobs, installing software, automation
- 🔒 **[Production Security Guide](PRODUCTION_SECURITY.md)** - Hardening for production deployment
- ⚡ **[Quick Reference](QUICK_REFERENCE.md)** - Common commands and troubleshooting
- 📋 **[Setup Summary](SETUP_SUMMARY.md)** - Complete setup explanation

## �📝 License

This project is open source and available under the MIT License.

## 👤 Author

**psyunix**
- GitHub: [@psyunix](https://github.com/psyunix)

## 🙏 Acknowledgments

- [Jenkins Official Docker Image](https://hub.docker.com/r/jenkins/jenkins)
- [Ubuntu Official Docker Image](https://hub.docker.com/_/ubuntu)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Made with ❤️ for CI/CD automation**
