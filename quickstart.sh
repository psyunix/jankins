#!/bin/bash

# Jankins Quick Start Script
# This script will build and start all services

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
echo "║          JENKINS QUICK START SCRIPT            ║"
echo "║   Jenkins CI/CD + Web Server Deployment       ║"
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

# Check if docker-compose is available
print_info "Checking Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed."
    exit 1
fi

print_success "Docker Compose is available"

# Stop and remove existing containers
print_info "Cleaning up existing containers..."
docker-compose down -v 2>/dev/null || true
print_success "Cleanup complete"

# Build images
print_info "Building Docker images..."
docker-compose build --no-cache

print_success "Docker images built successfully"

# Start services
print_info "Starting services..."
docker-compose up -d

print_success "Services started"

# Wait for Jenkins
print_info "Waiting for Jenkins to be ready (this may take 1-2 minutes)..."
timeout 120 bash -c 'until curl -f http://localhost:8080/login 2>/dev/null; do echo -n "."; sleep 5; done' && echo
print_success "Jenkins is ready!"

# Wait for Web Server
print_info "Waiting for Web Server to be ready..."
timeout 60 bash -c 'until curl -f http://localhost:8081 2>/dev/null; do echo -n "."; sleep 3; done' && echo
print_success "Web Server is ready!"

# Get Jenkins initial password
print_info "Retrieving Jenkins initial admin password..."
sleep 5
JENKINS_PASSWORD=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Not available - setup wizard disabled")

# Print summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           DEPLOYMENT SUCCESSFUL! 🎉            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Services Status:${NC}"
echo ""
docker-compose ps
echo ""
echo -e "${BLUE}🌐 Access URLs:${NC}"
echo -e "   ${GREEN}Jenkins:${NC}     http://localhost:8080"
echo -e "   ${GREEN}Web Server:${NC}  http://localhost:8081"
echo ""

if [ "$JENKINS_PASSWORD" != "Not available - setup wizard disabled" ]; then
    echo -e "${BLUE}🔐 Jenkins Initial Admin Password:${NC}"
    echo -e "   ${YELLOW}$JENKINS_PASSWORD${NC}"
    echo ""
fi

echo -e "${BLUE}📝 Useful Commands:${NC}"
echo -e "   View logs:        ${YELLOW}docker-compose logs -f${NC}"
echo -e "   Stop services:    ${YELLOW}docker-compose down${NC}"
echo -e "   Restart services: ${YELLOW}docker-compose restart${NC}"
echo -e "   View status:      ${YELLOW}docker-compose ps${NC}"
echo ""

print_info "Opening services in your browser..."
sleep 2

# Try to open in browser (macOS)
if command -v open &> /dev/null; then
    open http://localhost:8080 2>/dev/null || true
    open http://localhost:8081 2>/dev/null || true
fi

print_success "Setup complete! Enjoy your Jenkins deployment! 🚀"
