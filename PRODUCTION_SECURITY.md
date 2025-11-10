# 🔒 Production Security Hardening Guide

This guide covers how to secure your Jankins deployment for production use.

## 📋 Table of Contents

1. [Database Credentials Security](#1-database-credentials-security)
2. [Environment Variables & Secrets](#2-environment-variables--secrets)
3. [HTTPS/TLS Configuration](#3-httpstls-configuration)
4. [Jenkins Security Configuration](#4-jenkins-security-configuration)
5. [Docker Secrets Management](#5-docker-secrets-management)
6. [Network Isolation](#6-network-isolation)
7. [Firewall Configuration](#7-firewall-configuration)
8. [Regular Security Updates](#8-regular-security-updates)
9. [Complete Production Example](#9-complete-production-example)

---

## 1. Database Credentials Security

### Step 1: Create Environment File

Create a `.env` file (never commit this!):

```bash
# .env
# Database Configuration
DB_ROOT_PASSWORD=your_super_secure_root_password_here
DB_NAME=production_db
DB_USER=prod_user
DB_PASSWORD=your_secure_password_here_min_16_chars

# Jenkins Configuration
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=your_jenkins_admin_password

# GitHub Container Registry
GHCR_TOKEN=your_github_personal_access_token
```

### Step 2: Update .gitignore

Add to `.gitignore`:

```bash
# Environment files with secrets
.env
.env.local
.env.production
*.env

# Sensitive data
secrets/
*.key
*.pem
*.crt
```

### Step 3: Update Web Server Dockerfile

Edit `Dockerfile.webserver`:

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && \
    apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    libapache2-mod-php \
    curl \
    vim \
    mc \
    htop \
    net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite php8.1

COPY webserver/index.php /var/www/html/
COPY webserver/db-test.php /var/www/html/
COPY webserver/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

COPY webserver/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 80

CMD ["/usr/local/bin/start.sh"]
```

### Step 4: Update init-db.sh to Use Environment Variables

Edit `webserver/init-db.sh`:

```bash
#!/bin/bash

# Get credentials from environment variables
DB_NAME="${DB_NAME:-testdb}"
DB_USER="${DB_USER:-testuser}"
DB_PASSWORD="${DB_PASSWORD:-testpass123}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-rootpass123}"

# Start MariaDB
service mariadb start

# Wait for MariaDB to be ready
until mysqladmin ping -h localhost --silent; do
    echo 'Waiting for MariaDB to be available...'
    sleep 2
done

# Set root password if provided
if [ -n "$DB_ROOT_PASSWORD" ]; then
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
fi

# Create database and user with environment variables
mysql -u root -p"${DB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Create test table
mysql -u root -p"${DB_ROOT_PASSWORD}" ${DB_NAME} <<EOF
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO users (id, name, email) VALUES
    (1, 'John Doe', 'john@example.com'),
    (2, 'Jane Smith', 'jane@example.com'),
    (3, 'Bob Johnson', 'bob@example.com'),
    (4, 'Alice Williams', 'alice@example.com');
EOF

echo "Database initialized successfully with secure credentials!"
```

### Step 5: Update db-test.php

Edit `webserver/db-test.php` to use environment variables:

```php
<?php
// Get database credentials from environment variables
$host = 'localhost';
$dbname = getenv('DB_NAME') ?: 'testdb';
$username = getenv('DB_USER') ?: 'testuser';
$password = getenv('DB_PASSWORD') ?: 'testpass123';

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    // Rest of your code...
    
} catch (Exception $e) {
    // Handle error
}
?>
```

### Step 6: Update docker-compose.yml

Create `docker-compose.production.yml`:

```yaml
version: '3.8'

services:
  jenkins:
    image: ghcr.io/psyunix/jankins/jenkins:latest
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JENKINS_OPTS=--prefix=/jenkins
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    env_file:
      - .env
    networks:
      - jankins-network
    secrets:
      - jenkins_admin_password

  webserver:
    image: ghcr.io/psyunix/jankins/webserver:latest
    container_name: webserver
    restart: unless-stopped
    ports:
      - "8081:80"
    volumes:
      - ./webserver:/var/www/html
    environment:
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
    env_file:
      - .env
    networks:
      - jankins-network
    secrets:
      - db_password
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  jenkins_home:
    driver: local

networks:
  jankins-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16

secrets:
  jenkins_admin_password:
    file: ./secrets/jenkins_admin_password.txt
  db_password:
    file: ./secrets/db_password.txt
```

---

## 2. Environment Variables & Secrets

### Create Secrets Directory

```bash
mkdir -p secrets
chmod 700 secrets

# Create secret files
echo "your_jenkins_admin_password" > secrets/jenkins_admin_password.txt
echo "your_database_password" > secrets/db_password.txt

# Secure the files
chmod 600 secrets/*.txt
```

### Generate Strong Passwords

```bash
# Generate random passwords
openssl rand -base64 32 > secrets/db_password.txt
openssl rand -base64 32 > secrets/jenkins_admin_password.txt
```

### Use docker-compose with Secrets

```bash
docker-compose -f docker-compose.production.yml up -d
```

---

## 3. HTTPS/TLS Configuration

### Option A: Using Nginx Reverse Proxy

Create `docker-compose.production.yml` with Nginx:

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
    depends_on:
      - jenkins
      - webserver
    networks:
      - jankins-network

  jenkins:
    image: ghcr.io/psyunix/jankins/jenkins:latest
    container_name: jenkins
    restart: unless-stopped
    expose:
      - "8080"
      - "50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    env_file:
      - .env
    networks:
      - jankins-network

  webserver:
    image: ghcr.io/psyunix/jankins/webserver:latest
    container_name: webserver
    restart: unless-stopped
    expose:
      - "80"
    volumes:
      - ./webserver:/var/www/html
    env_file:
      - .env
    networks:
      - jankins-network

volumes:
  jenkins_home:

networks:
  jankins-network:
    driver: bridge
```

### Create Nginx Configuration

Create `nginx/conf.d/default.conf`:

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

# Jenkins HTTPS
server {
    listen 443 ssl http2;
    server_name jenkins.your-domain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://jenkins:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for Jenkins
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}

# Web Server HTTPS
server {
    listen 443 ssl http2;
    server_name app.your-domain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://webserver:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Generate Self-Signed Certificate (for testing)

```bash
mkdir -p nginx/ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"
```

### Use Let's Encrypt (for production)

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d jenkins.your-domain.com -d app.your-domain.com

# Auto-renewal
sudo certbot renew --dry-run
```

---

## 4. Jenkins Security Configuration

### Step 1: Enable Security Realm

1. Go to **Manage Jenkins** → **Configure Global Security**
2. Check **Enable security**
3. Select **Jenkins' own user database**
4. Uncheck **Allow users to sign up**

### Step 2: Authorization Strategy

Select **Matrix-based security**:

- **Anonymous:** Read (only if needed)
- **Authenticated Users:** Overall/Read, Job/Build, Job/Read
- **Admin User:** All permissions

### Step 3: Configure CSRF Protection

1. Check **Prevent Cross Site Request Forgery exploits**
2. Select **Default Crumb Issuer**

### Step 4: Agent Security

1. Set **TCP port for inbound agents:** Fixed (50000)
2. Enable **Agent → Controller Access Control**

### Step 5: Disable CLI

```bash
# In Jenkins container
docker exec jenkins bash -c "echo 'jenkins.CLI.disabled=true' >> /var/jenkins_home/jenkins.model.JenkinsLocationConfiguration.xml"
```

### Step 6: Security Headers

Add to Jenkins Java options in docker-compose.yml:

```yaml
environment:
  - JAVA_OPTS=-Djenkins.install.runSetupWizard=false 
      -Dhudson.model.DirectoryBrowserSupport.CSP="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
```

---

## 5. Docker Secrets Management

### Create Secrets

```bash
# Create secrets directory
mkdir -p secrets

# Database password
echo "super_secure_db_password_$(openssl rand -hex 16)" > secrets/db_password.txt

# Root password
echo "super_secure_root_password_$(openssl rand -hex 16)" > secrets/db_root_password.txt

# Jenkins admin password
echo "jenkins_admin_password_$(openssl rand -hex 16)" > secrets/jenkins_admin_password.txt

# Secure permissions
chmod 600 secrets/*
```

### Use in docker-compose.yml

```yaml
version: '3.8'

services:
  webserver:
    image: ghcr.io/psyunix/jankins/webserver:latest
    secrets:
      - db_password
      - db_root_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - DB_ROOT_PASSWORD_FILE=/run/secrets/db_root_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
  db_root_password:
    file: ./secrets/db_root_password.txt
  jenkins_admin_password:
    file: ./secrets/jenkins_admin_password.txt
```

### Update Scripts to Read Secrets

Edit `webserver/init-db.sh`:

```bash
#!/bin/bash

# Read passwords from Docker secrets if available
if [ -f "/run/secrets/db_password" ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
fi

if [ -f "/run/secrets/db_root_password" ]; then
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
fi

# Use environment variables as fallback
DB_PASSWORD="${DB_PASSWORD:-${DB_PASSWORD:-testpass123}}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-${DB_ROOT_PASSWORD:-rootpass123}}"

# Rest of the script...
```

---

## 6. Network Isolation

### Create Separate Networks

```yaml
version: '3.8'

services:
  jenkins:
    networks:
      - jenkins-net
      - public-net

  webserver:
    networks:
      - webserver-net
      - public-net

  database:
    image: mariadb:10.6
    networks:
      - webserver-net
    # No public-net - isolated from external access

networks:
  jenkins-net:
    driver: bridge
    internal: true
  webserver-net:
    driver: bridge
    internal: true
  public-net:
    driver: bridge
```

### Use Custom Subnets

```yaml
networks:
  jankins-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
          gateway: 172.28.0.1
```

---

## 7. Firewall Configuration

### UFW (Ubuntu Firewall)

```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Block direct access to Jenkins (use Nginx instead)
sudo ufw deny 8080/tcp

# Block direct access to web server
sudo ufw deny 8081/tcp

# Allow from specific IP only
sudo ufw allow from 192.168.1.100 to any port 8080

# Check status
sudo ufw status numbered
```

### iptables

```bash
# Block external access to Jenkins
sudo iptables -A INPUT -p tcp --dport 8080 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j DROP

# Allow only specific IP
sudo iptables -A INPUT -p tcp --dport 8080 -s 192.168.1.100 -j ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### Docker Firewall

Create custom Docker network rules:

```bash
# In daemon.json
{
  "iptables": true,
  "userland-proxy": false
}
```

---

## 8. Regular Security Updates

### Automated OS Updates

Create systemd timer:

```bash
# /etc/systemd/system/docker-update.service
[Unit]
Description=Update Docker containers
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-containers.sh

[Install]
WantedBy=multi-user.target
```

```bash
# /etc/systemd/system/docker-update.timer
[Unit]
Description=Update Docker containers monthly
Requires=docker-update.service

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
```

### Update Script

Create `/usr/local/bin/update-containers.sh`:

```bash
#!/bin/bash

cd /path/to/jankins

# Pull latest images
docker-compose -f docker-compose.production.yml pull

# Recreate containers with new images
docker-compose -f docker-compose.production.yml up -d --force-recreate

# Clean up old images
docker image prune -af

# Log the update
echo "$(date): Containers updated" >> /var/log/docker-updates.log
```

```bash
chmod +x /usr/local/bin/update-containers.sh
sudo systemctl enable docker-update.timer
sudo systemctl start docker-update.timer
```

### Security Scanning

```bash
# Install Trivy
wget https://github.com/aquasecurity/trivy/releases/download/v0.45.0/trivy_0.45.0_Linux-64bit.tar.gz
tar zxvf trivy_*.tar.gz
sudo mv trivy /usr/local/bin/

# Scan images
trivy image ghcr.io/psyunix/jankins/jenkins:latest
trivy image ghcr.io/psyunix/jankins/webserver:latest
```

---

## 9. Complete Production Example

Create `docker-compose.production.yml`:

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - nginx-logs:/var/log/nginx
    networks:
      - public-net
    depends_on:
      - jenkins
      - webserver

  jenkins:
    image: ghcr.io/psyunix/jankins/jenkins:latest
    container_name: jenkins-prod
    restart: unless-stopped
    expose:
      - "8080"
      - "50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xmx2048m
      - JENKINS_OPTS=--prefix=/jenkins
    secrets:
      - jenkins_admin_password
    networks:
      - jenkins-net
      - public-net
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080/login || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  webserver:
    image: ghcr.io/psyunix/jankins/webserver:latest
    container_name: webserver-prod
    restart: unless-stopped
    expose:
      - "80"
    volumes:
      - ./webserver:/var/www/html:ro
      - webserver-logs:/var/log/apache2
    environment:
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
    secrets:
      - db_password
      - db_root_password
    networks:
      - webserver-net
      - public-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  jenkins_home:
    driver: local
  nginx-logs:
    driver: local
  webserver-logs:
    driver: local

networks:
  public-net:
    driver: bridge
  jenkins-net:
    driver: bridge
    internal: true
  webserver-net:
    driver: bridge
    internal: true

secrets:
  jenkins_admin_password:
    file: ./secrets/jenkins_admin_password.txt
  db_password:
    file: ./secrets/db_password.txt
  db_root_password:
    file: ./secrets/db_root_password.txt
```

### Deployment Script

Create `deploy-production.sh`:

```bash
#!/bin/bash

set -e

echo "🔒 Production Deployment Script"
echo "==============================="

# Check for required files
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "Creating from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env with production values!"
    exit 1
fi

# Create secrets if they don't exist
if [ ! -d "secrets" ]; then
    echo "Creating secrets directory..."
    mkdir -p secrets
    chmod 700 secrets
    
    echo "Generating secure passwords..."
    openssl rand -base64 32 > secrets/db_password.txt
    openssl rand -base64 32 > secrets/db_root_password.txt
    openssl rand -base64 32 > secrets/jenkins_admin_password.txt
    
    chmod 600 secrets/*.txt
    
    echo "✅ Secrets created. Please save these passwords securely!"
fi

# Pull latest images
echo "📦 Pulling latest images..."
docker-compose -f docker-compose.production.yml pull

# Start services
echo "🚀 Starting services..."
docker-compose -f docker-compose.production.yml up -d

# Wait for services
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check health
echo "🏥 Checking service health..."
docker-compose -f docker-compose.production.yml ps

echo ""
echo "✅ Production deployment complete!"
echo ""
echo "📊 Access your services:"
echo "  - Jenkins: https://jenkins.your-domain.com"
echo "  - Web App: https://app.your-domain.com"
echo ""
echo "🔑 Retrieve passwords from secrets/ directory"
```

```bash
chmod +x deploy-production.sh
./deploy-production.sh
```

---

## 📋 Security Checklist

- [ ] Change all default passwords
- [ ] Use `.env` files for configuration
- [ ] Never commit secrets to git
- [ ] Enable HTTPS/TLS with valid certificates
- [ ] Configure Jenkins security realm and authorization
- [ ] Use Docker secrets for sensitive data
- [ ] Implement network isolation
- [ ] Configure firewall rules
- [ ] Set up automated updates
- [ ] Enable security scanning
- [ ] Configure logging and monitoring
- [ ] Regular security audits
- [ ] Backup Jenkins configuration
- [ ] Backup database regularly
- [ ] Use strong passwords (16+ characters)
- [ ] Enable 2FA where possible
- [ ] Limit Jenkins user permissions
- [ ] Disable unnecessary Jenkins plugins
- [ ] Regular dependency updates
- [ ] Monitor security advisories

---

## 🆘 Emergency Response

If compromised:

1. **Immediately stop services:**
   ```bash
   docker-compose -f docker-compose.production.yml down
   ```

2. **Change all passwords**

3. **Review logs:**
   ```bash
   docker-compose -f docker-compose.production.yml logs > incident.log
   ```

4. **Scan for vulnerabilities:**
   ```bash
   trivy image ghcr.io/psyunix/jankins/jenkins:latest
   ```

5. **Rebuild from clean images**

6. **Update all dependencies**

---

**Security is ongoing! Stay vigilant! 🛡️**
