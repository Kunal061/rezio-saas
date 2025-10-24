#!/bin/bash

###############################################################################
# Emergency Disk Space Cleanup Script
# Run this when EC2 is running out of disk space
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${RED}═══════════════════════════════════════════════════${NC}"
echo -e "${RED}    EMERGENCY DISK SPACE CLEANUP${NC}"
echo -e "${RED}═══════════════════════════════════════════════════${NC}"
echo ""

# Check current disk usage
echo -e "${YELLOW}Current disk usage:${NC}"
df -h /
echo ""

DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo -e "${YELLOW}Disk usage: ${DISK_USAGE}%${NC}"

if [ $DISK_USAGE -lt 80 ]; then
    echo -e "${GREEN}✓ Disk usage is fine (< 80%)${NC}"
    echo "Cleanup may not be necessary, but proceeding anyway..."
fi

echo ""
read -p "Continue with cleanup? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 1: Docker Cleanup${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

# Stop application container
echo -e "${YELLOW}Stopping application container...${NC}"
docker stop rezio-saas-container 2>/dev/null || echo "No container running"
docker rm rezio-saas-container 2>/dev/null || echo "No container to remove"

# Remove all stopped containers
echo -e "${YELLOW}Removing all stopped containers...${NC}"
docker container prune -a -f

# Remove all unused images
echo -e "${YELLOW}Removing all unused images...${NC}"
docker image prune -a -f

# Remove all unused volumes
echo -e "${YELLOW}Removing all unused volumes...${NC}"
docker volume prune -f

# Remove all build cache
echo -e "${YELLOW}Removing all build cache...${NC}"
docker builder prune -a -f

# Remove unused networks
echo -e "${YELLOW}Removing unused networks...${NC}"
docker network prune -f

echo -e "${GREEN}✓ Docker cleanup completed${NC}"

# Show Docker disk usage
echo ""
echo -e "${YELLOW}Docker disk usage:${NC}"
docker system df

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 2: NPM Cache Cleanup${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

echo -e "${YELLOW}Cleaning npm cache...${NC}"
rm -rf ~/.npm
rm -rf /home/ubuntu/.npm 2>/dev/null || true
echo -e "${GREEN}✓ NPM cache cleaned${NC}"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 3: System Cleanup${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

# Clean /tmp
echo -e "${YELLOW}Cleaning /tmp directory...${NC}"
sudo rm -rf /tmp/*
echo -e "${GREEN}✓ /tmp cleaned${NC}"

# Clean journal logs (keep last 3 days)
echo -e "${YELLOW}Cleaning old journal logs...${NC}"
sudo journalctl --vacuum-time=3d
echo -e "${GREEN}✓ Journal logs cleaned${NC}"

# Clean apt cache (Ubuntu/Debian)
if command -v apt-get &> /dev/null; then
    echo -e "${YELLOW}Cleaning apt cache...${NC}"
    sudo apt-get clean
    sudo apt-get autoclean
    echo -e "${GREEN}✓ APT cache cleaned${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 4: Find Large Files${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

echo -e "${YELLOW}Top 10 largest directories:${NC}"
du -h / 2>/dev/null | sort -rh | head -10

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Cleanup Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

echo -e "${YELLOW}Disk usage after cleanup:${NC}"
df -h /

DISK_USAGE_AFTER=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
FREED=$((DISK_USAGE - DISK_USAGE_AFTER))

echo ""
echo -e "${GREEN}✓ Cleanup completed!${NC}"
echo -e "${GREEN}Freed approximately ${FREED}% of disk space${NC}"
echo ""

if [ $DISK_USAGE_AFTER -gt 85 ]; then
    echo -e "${RED}⚠ WARNING: Disk usage still high (${DISK_USAGE_AFTER}%)${NC}"
    echo -e "${YELLOW}Consider:${NC}"
    echo -e "  1. Increasing EBS volume size in AWS Console"
    echo -e "  2. Deleting old Jenkins workspaces"
    echo -e "  3. Removing old Docker images manually"
    echo ""
    echo -e "${YELLOW}To increase EBS volume:${NC}"
    echo -e "  1. AWS Console → EC2 → Volumes"
    echo -e "  2. Select your volume → Actions → Modify Volume"
    echo -e "  3. Increase size from current to 20-30 GB"
    echo -e "  4. On EC2, run: sudo growpart /dev/xvda 1 && sudo resize2fs /dev/xvda1"
else
    echo -e "${GREEN}✓ Disk usage is now acceptable (${DISK_USAGE_AFTER}%)${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
