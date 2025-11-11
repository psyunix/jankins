# 🐳 Using Pre-built Docker Images from GitHub Container Registry

This guide explains how to use the pre-built Docker images published to GitHub Container Registry (GHCR).

## 📦 Available Images

The following images are automatically built and published on every push to the main branch:

- **Jenkins:** `ghcr.io/psyunix/jenkins/jenkins:latest`
- **Web Server:** `ghcr.io/psyunix/jenkins/webserver:latest`

## 🚀 Quick Start with Pre-built Images

### Option 1: Use the Pull and Run Script (Easiest)

```bash
chmod +x pull-and-run.sh
./pull-and-run.sh
```

This script will:
1. Pull the latest images from GHCR
2. Start all services
3. Wait for services to be ready
4. Open your browser

### Option 2: Manual Docker Compose

```bash
# Pull latest images
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
docker pull ghcr.io/psyunix/jenkins/webserver:latest

# Start services
docker-compose -f docker-compose.ghcr.yml up -d
```

### Option 3: Direct Docker Pull

```bash
# Pull Jenkins image
docker pull ghcr.io/psyunix/jenkins/jenkins:latest

# Pull Web Server image
docker pull ghcr.io/psyunix/jenkins/webserver:latest

# Run Jenkins
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  ghcr.io/psyunix/jenkins/jenkins:latest

# Run Web Server
docker run -d \
  --name webserver \
  -p 8081:80 \
  ghcr.io/psyunix/jenkins/webserver:latest
```

## 🏷️ Available Tags

Images are tagged with multiple tags for flexibility:

- `latest` - Always points to the latest build from main branch
- `main` - Same as latest
- `v1.0.0` - Semantic version tags (when you create releases)
- `main-<sha>` - Specific commit SHA

### Pull Specific Version

```bash
# Pull specific version
docker pull ghcr.io/psyunix/jenkins/jenkins:v1.0.0

# Pull specific commit
docker pull ghcr.io/psyunix/jenkins/jenkins:main-abc123
```

## 🔄 Automatic Image Builds

Images are automatically built and pushed when:

1. **Push to main/master branch** - Creates `latest` and `main` tags
2. **Create a tag** (e.g., `v1.0.0`) - Creates version-specific tags
3. **Manual trigger** - Via GitHub Actions UI

## 📊 View Published Packages

Visit your GitHub repository packages:
- https://github.com/psyunix?tab=packages

Or directly:
- https://github.com/psyunix/jenkins/pkgs/container/jenkins%2Fjenkins
- https://github.com/psyunix/jenkins/pkgs/container/jenkins%2Fwebserver

## 🔓 Image Visibility

By default, GitHub Container Registry images are **private**. To make them public:

1. Go to https://github.com/psyunix?tab=packages
2. Click on the package name
3. Click "Package settings"
4. Scroll to "Danger Zone"
5. Click "Change visibility"
6. Select "Public"

**Note:** You need to do this for both images (jenkins and webserver).

## 🔑 Authentication (for Private Images)

If images are private, you need to authenticate:

```bash
# Create a Personal Access Token (PAT) with read:packages scope
# Then login to GHCR
echo $YOUR_PAT | docker login ghcr.io -u USERNAME --password-stdin

# Now you can pull private images
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
```

## 📝 Update Your Local Setup

### Switch from Local Build to Pre-built Images

Edit your `docker-compose.yml`:

```yaml
services:
  jenkins:
    # Comment out the build section
    # build:
    #   context: .
    #   dockerfile: Dockerfile.jenkins
    
    # Add the image line
    image: ghcr.io/psyunix/jenkins/jenkins:latest
```

Or simply use the provided `docker-compose.ghcr.yml`:

```bash
docker-compose -f docker-compose.ghcr.yml up -d
```

## 🔄 Update to Latest Images

Pull the latest versions:

```bash
# Pull latest
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
docker pull ghcr.io/psyunix/jenkins/webserver:latest

# Recreate containers with new images
docker-compose -f docker-compose.ghcr.yml up -d --force-recreate
```

Or use the script:

```bash
./pull-and-run.sh
```

## 🏗️ Build Workflow Details

The build workflow (`.github/workflows/build-images.yml`) includes:

- **Multi-platform support** - Builds for amd64 (can be extended for arm64)
- **Layer caching** - Speeds up subsequent builds
- **Metadata tagging** - Automatic version tagging
- **GitHub token auth** - No manual credentials needed

## 📊 Build Status

Check the build status:
- https://github.com/psyunix/jenkins/actions/workflows/build-images.yml

## 🎯 Benefits of Pre-built Images

1. **Faster Deployment** - No need to build locally (~40s build time saved)
2. **Consistent Builds** - Same image everywhere
3. **Version Control** - Easy to roll back to previous versions
4. **CI/CD Ready** - Pull and deploy in any environment
5. **Storage Efficient** - No need to store build context locally

## 🔍 Inspect Images

```bash
# View image details
docker inspect ghcr.io/psyunix/jenkins/jenkins:latest

# View image layers
docker history ghcr.io/psyunix/jenkins/jenkins:latest

# View image size
docker images ghcr.io/psyunix/jenkins/jenkins:latest
```

## 🚀 Deploy Anywhere

Since images are in GHCR, you can deploy them anywhere:

```bash
# On any server with Docker
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
docker pull ghcr.io/psyunix/jenkins/webserver:latest
docker-compose -f docker-compose.ghcr.yml up -d
```

## 🛠️ Troubleshooting

### Images Not Found

If you get "not found" errors:

1. Check if workflow completed successfully
2. Verify images are public (or authenticate)
3. Check image name spelling

### Authentication Issues

```bash
# Logout and login again
docker logout ghcr.io
echo $GITHUB_TOKEN | docker login ghcr.io -u psyunix --password-stdin
```

### Pull Rate Limits

GitHub Container Registry has generous limits:
- **Public images:** Unlimited pulls
- **Private images:** Based on your GitHub plan

## 📋 Complete Example

```bash
# 1. Clone repository (or just create a directory)
git clone https://github.com/psyunix/jenkins.git
cd jenkins

# 2. Pull pre-built images and start
./pull-and-run.sh

# 3. Access services
# Jenkins: http://localhost:8080
# Web Server: http://localhost:8081

# 4. Stop services
docker-compose -f docker-compose.ghcr.yml down

# 5. Update to latest and restart
docker pull ghcr.io/psyunix/jenkins/jenkins:latest
docker pull ghcr.io/psyunix/jenkins/webserver:latest
docker-compose -f docker-compose.ghcr.yml up -d --force-recreate
```

## 🎉 Summary

You now have:
- ✅ Automated image builds on GitHub
- ✅ Images published to GHCR
- ✅ Easy pull and run scripts
- ✅ Version-tagged images
- ✅ Fast deployment anywhere

**No more waiting for local builds!** Just pull and run! 🚀
