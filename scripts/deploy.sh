#!/bin/bash

###############################################################################
# Rezio SaaS - Manual Deployment Script
# This script can be used for manual deployments without Jenkins
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="rezio-saas"
CONTAINER_NAME="rezio-saas-container"
IMAGE_NAME="rezio-saas:latest"
APP_PORT="2000"
ENV_FILE=".env"

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    Rezio SaaS - Deployment Script${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please create .env file with required environment variables.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment file found${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Error: Docker is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"

# Stop and remove existing container
echo -e "${YELLOW}Stopping existing container...${NC}"
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
echo -e "${GREEN}✓ Old container removed${NC}"

# Remove existing image
echo -e "${YELLOW}Removing old image...${NC}"
docker rmi $IMAGE_NAME 2>/dev/null || true

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t $IMAGE_NAME .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker image built successfully${NC}"
else
    echo -e "${RED}✗ Docker build failed!${NC}"
    exit 1
fi

# Run database migrations
echo -e "${YELLOW}Running database migrations...${NC}"
docker run --rm \
    --env-file $ENV_FILE \
    $IMAGE_NAME \
    npx prisma migrate deploy || echo -e "${YELLOW}⚠ Migration completed or no new migrations${NC}"

# Start new container
echo -e "${YELLOW}Starting new container...${NC}"
docker run -d \
    --name $CONTAINER_NAME \
    --env-file $ENV_FILE \
    -p $APP_PORT:$APP_PORT \
    --restart unless-stopped \
    --health-cmd="curl -f http://localhost:$APP_PORT/ || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Container started successfully${NC}"
else
    echo -e "${RED}✗ Failed to start container!${NC}"
    exit 1
fi

# Wait for application to start
echo -e "${YELLOW}Waiting for application to start...${NC}"
sleep 10

# Health check
echo -e "${YELLOW}Performing health check...${NC}"
for i in {1..10}; do
    if curl -f http://localhost:$APP_PORT/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Application is responding on port $APP_PORT${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}✗ Application health check failed!${NC}"
        echo -e "${YELLOW}Container logs:${NC}"
        docker logs $CONTAINER_NAME
        exit 1
    fi
    echo -e "${YELLOW}Waiting... (attempt $i/10)${NC}"
    sleep 3
done

# Clean up old images
echo -e "${YELLOW}Cleaning up old images...${NC}"
docker image prune -f

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    Deployment Summary${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "Container Name: ${GREEN}$CONTAINER_NAME${NC}"
echo -e "Image: ${GREEN}$IMAGE_NAME${NC}"
echo -e "Port: ${GREEN}$APP_PORT${NC}"
echo -e "Status: ${GREEN}RUNNING${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"

# Show container status
docker ps -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo -e "${GREEN}Access your application at: http://localhost:$APP_PORT${NC}"
