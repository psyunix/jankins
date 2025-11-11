# 🚀 Quick Reference Guide

## 📦 Docker Images Githab

### Pre-built Images (GitHub Container Registry)
```bash
# Jenkins
ghcr.io/psyunix/jenkins/jenkins:latest

# Web Server
ghcr.io/psyunix/jenkins/webserver:latest
```

## 🎯 Quick Commands

### Deploy with Pre-built Images (Fastest)
```bash
./pull-and-run.sh
```

### Deploy with Local Build
```bash
./quickstart.sh
```

### Using Docker Compose

#### Pre-built Images
```bash
# Start
docker-compose -f docker-compose.ghcr.yml up -d

# Stop
docker-compose -f docker-compose.ghcr.yml down

# View logs
docker-compose -f docker-compose.ghcr.yml logs -f

# Update images
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
docker pull ghcr.io/psyunix/jenkins/webserver:latest
docker-compose -f docker-compose.ghcr.yml up -d --force-recreate
```

#### Local Build
```bash
# Build
docker-compose build

# Start
docker-compose up -d

# Stop
docker-compose down

# Rebuild
docker-compose build --no-cache
docker-compose up -d --force-recreate
```

### Manual Docker Commands

#### Pull Images
```bash
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
docker pull ghcr.io/psyunix/jenkins/webserver:latest
```

#### Run Jenkins
```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/psyunix/jenkins/jenkins:latest
```

#### Run Web Server
```bash
docker run -d \
  --name webserver \
  -p 8081:80 \
  ghcr.io/psyunix/jenkins/webserver:latest
```

## 🌐 Access URLs

- **Jenkins:** http://localhost:8080
- **Web Server:** http://localhost:8081
- **Database Test:** http://localhost:8081/db-test.php

## 🔑 Credentials

### Database
- **Host:** localhost
- **Database:** testdb
- **Username:** testuser
- **Password:** testpass123

## 📊 Monitoring

### View Container Status
```bash
docker ps
docker-compose ps
docker-compose -f docker-compose.ghcr.yml ps
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker logs jenkins -f
docker logs webserver -f

# Last 100 lines
docker logs --tail 100 jenkins
```

### Resource Usage
```bash
docker stats
```

### Container Details
```bash
docker inspect jenkins
docker inspect webserver
```

## 🧹 Cleanup

### Stop Services
```bash
docker-compose down
docker-compose -f docker-compose.ghcr.yml down
```

### Remove Volumes (Complete Reset)
```bash
docker-compose down -v
docker-compose -f docker-compose.ghcr.yml down -v
```

### Remove Images
```bash
# Remove local build images
docker rmi jenkins-jenkins jenkins-webserver

# Remove GHCR images
docker rmi ghcr.io/psyunix/jenkins/jenkins:latest
docker rmi ghcr.io/psyunix/jenkins/webserver:latest
```

### Full Cleanup
```bash
# Stop everything
docker-compose down -v

# Remove all containers
docker rm -f $(docker ps -aq)

# Remove all images
docker rmi -f $(docker images -q)

# Prune system
docker system prune -a --volumes
```

## 🔄 Update & Restart

### Update Pre-built Images
```bash
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
docker pull ghcr.io/psyunix/jenkins/webserver:latest
docker-compose -f docker-compose.ghcr.yml up -d --force-recreate
```

### Rebuild Local Images
```bash
docker-compose build --no-cache
docker-compose up -d --force-recreate
```

### Restart Services
```bash
docker-compose restart
docker-compose -f docker-compose.ghcr.yml restart

# Specific service
docker restart jenkins
docker restart webserver
```

## 🐛 Debugging

### Enter Container Shell
```bash
# Jenkins
docker exec -it jenkins bash

# Web Server
docker exec -it webserver bash
```

### Check Service Status Inside Container
```bash
# Web Server - Check Apache
docker exec webserver service apache2 status

# Web Server - Check MariaDB
docker exec webserver service mariadb status
```

### Test Database Connection
```bash
docker exec webserver mysql -u testuser -ptestpass123 testdb -e "SELECT * FROM users;"
```

### Check Network
```bash
docker network ls
docker network inspect jenkins_jenkins-network
```

### Check Volumes
```bash
docker volume ls
docker volume inspect jenkins_jenkins_home
```

## 🔧 Troubleshooting

### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Jenkins Won't Start
```bash
# Check logs
docker logs jenkins

# Check disk space
df -h

# Restart
docker restart jenkins
```

### Web Server Database Issues
```bash
# Reinitialize database
docker exec webserver /usr/local/bin/init-db.sh

# Check MariaDB logs
docker exec webserver tail -f /var/log/mysql/error.log
```

### Cannot Pull Images (Private)
```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u psyunix --password-stdin

# Then pull
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
```

## 📚 Documentation

- **Main README:** [README.md](README.md)
- **GHCR Usage:** [GHCR_USAGE.md](GHCR_USAGE.md)
- **Setup Summary:** [SETUP_SUMMARY.md](SETUP_SUMMARY.md)

## 🔗 Links

- **Repository:** https://github.com/psyunix/jenkins
- **Actions:** https://github.com/psyunix/jenkins/actions
- **Packages:** https://github.com/psyunix?tab=packages
- **CI Workflow:** https://github.com/psyunix/jenkins/actions/workflows/ci.yml
- **Build Workflow:** https://github.com/psyunix/jenkins/actions/workflows/build-images.yml

## ⚡ One-Liners

```bash
# Quick start with pre-built images
./pull-and-run.sh

# Quick start with local build
./quickstart.sh

# Pull latest and restart
docker pull ghcr.io/psyunix/jenkins/jenkins:latest && docker pull ghcr.io/psyunix/jenkins/webserver:latest && docker-compose -f docker-compose.ghcr.yml up -d --force-recreate

# View all logs
docker-compose logs -f

# Complete reset
docker-compose down -v && docker system prune -af --volumes && ./quickstart.sh

# Check everything is running
docker ps && curl -s -o /dev/null -w "Jenkins: %{http_code}\n" http://localhost:8080 && curl -s -o /dev/null -w "WebServer: %{http_code}\n" http://localhost:8081
```

---

**Quick Tip:** Bookmark this page for fast reference! 📖
