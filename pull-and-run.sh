#!/bin/bash

# Pull and Run Pre-built Images from GitHub Container Registry
# This script pulls pre-built Docker images and starts services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════╗"
echo "║     JANKINS - Pull Pre-built Images            ║"
echo "║     GitHub Container Registry (GHCR)           ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Image names
JENKINS_IMAGE="ghcr.io/psyunix/jankins/jenkins:latest"
WEBSERVER_IMAGE="ghcr.io/psyunix/jankins/webserver:latest"

# Check if Docker is running
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi

print_success "Docker is running"

# Stop existing containers
print_info "Stopping existing containers..."
docker-compose -f docker-compose.ghcr.yml down 2>/dev/null || true
print_success "Cleanup complete"

# Pull images from GitHub Container Registry
print_info "Pulling Jenkins image from GitHub Container Registry..."
if docker pull $JENKINS_IMAGE; then
    print_success "Jenkins image pulled successfully"
else
    print_error "Failed to pull Jenkins image. The image may not be public yet."
    print_warning "Building locally instead..."
    docker-compose build jenkins
fi

print_info "Pulling Web Server image from GitHub Container Registry..."
if docker pull $WEBSERVER_IMAGE; then
    print_success "Web Server image pulled successfully"
else
    print_error "Failed to pull Web Server image. The image may not be public yet."
    print_warning "Building locally instead..."
    docker-compose build webserver
fi

# Start services using pre-built images
print_info "Starting services with pre-built images..."
docker-compose -f docker-compose.ghcr.yml up -d

print_success "Services started"

# Wait for services
print_info "Waiting for Web Server to be ready..."
timeout 60 bash -c 'until curl -f http://localhost:8081 2>/dev/null; do echo -n "."; sleep 3; done' && echo
print_success "Web Server is ready!"

print_info "Waiting for Jenkins to be ready (this may take 1-2 minutes)..."
timeout 120 bash -c 'until curl -f http://localhost:8080 2>/dev/null; do echo -n "."; sleep 5; done' && echo
print_success "Jenkins is ready!"

# Print summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        IMAGES PULLED & DEPLOYED! 🎉            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Services Status:${NC}"
echo ""
docker-compose -f docker-compose.ghcr.yml ps
echo ""
echo -e "${BLUE}🌐 Access URLs:${NC}"
echo -e "   ${GREEN}Jenkins:${NC}     http://localhost:8080"
echo -e "   ${GREEN}Web Server:${NC}  http://localhost:8081"
echo ""
echo -e "${BLUE}🐳 Images Used:${NC}"
echo -e "   ${GREEN}Jenkins:${NC}     $JENKINS_IMAGE"
echo -e "   ${GREEN}Web Server:${NC}  $WEBSERVER_IMAGE"
echo ""
echo -e "${BLUE}📝 Useful Commands:${NC}"
echo -e "   View logs:        ${YELLOW}docker-compose -f docker-compose.ghcr.yml logs -f${NC}"
echo -e "   Stop services:    ${YELLOW}docker-compose -f docker-compose.ghcr.yml down${NC}"
echo -e "   Restart services: ${YELLOW}docker-compose -f docker-compose.ghcr.yml restart${NC}"
echo -e "   Pull latest:      ${YELLOW}docker pull $JENKINS_IMAGE && docker pull $WEBSERVER_IMAGE${NC}"
echo ""

print_info "Opening services in your browser..."
sleep 2

# Try to open in browser (macOS)
if command -v open &> /dev/null; then
    open http://localhost:8080 2>/dev/null || true
    open http://localhost:8081 2>/dev/null || true
fi

print_success "Setup complete! Using pre-built images from GHCR! 🚀"
