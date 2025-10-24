#!/bin/bash

###############################################################################
# Rezio SaaS - Rollback Script
# Rollback to a previous Docker image version
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_NAME="rezio-saas"
CONTAINER_NAME="rezio-saas-container"
APP_PORT="2000"
ENV_FILE=".env"

echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}    Rezio SaaS - Rollback Script${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"

# List available images
echo -e "${GREEN}Available images:${NC}"
docker images $APP_NAME --format "table {{.Tag}}\t{{.ID}}\t{{.CreatedAt}}" | head -10

echo ""
echo -e "${YELLOW}Enter the image tag or ID to rollback to:${NC}"
read -p "Image tag/ID: " IMAGE_TAG

if [ -z "$IMAGE_TAG" ]; then
    echo -e "${RED}✗ No image tag provided. Exiting.${NC}"
    exit 1
fi

# Verify image exists
if ! docker images --format "{{.Tag}} {{.ID}}" $APP_NAME | grep -q "$IMAGE_TAG"; then
    echo -e "${RED}✗ Image not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}Rolling back to: $APP_NAME:$IMAGE_TAG${NC}"
echo -e "${YELLOW}Are you sure? (yes/no)${NC}"
read -p "Confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}Rollback cancelled.${NC}"
    exit 0
fi

# Stop current container
echo -e "${YELLOW}Stopping current container...${NC}"
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Start container with old image
echo -e "${YELLOW}Starting container with previous image...${NC}"
docker run -d \
    --name $CONTAINER_NAME \
    --env-file $ENV_FILE \
    -p $APP_PORT:$APP_PORT \
    --restart unless-stopped \
    $APP_NAME:$IMAGE_TAG

# Health check
sleep 5
if curl -f http://localhost:$APP_PORT/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Rollback successful!${NC}"
    echo -e "${GREEN}Application is running on port $APP_PORT${NC}"
else
    echo -e "${RED}✗ Rollback may have issues. Check logs:${NC}"
    docker logs $CONTAINER_NAME
fi

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
docker ps -f name=$CONTAINER_NAME
