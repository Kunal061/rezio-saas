#!/bin/bash

###############################################################################
# Rezio SaaS - Jenkins Environment Fix Script
# Run this on your EC2 instance to fix Docker and .env issues
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Rezio SaaS - Jenkins Fix Script${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}This script will fix:${NC}"
echo -e "  1. Install Docker (if missing)"
echo -e "  2. Configure Jenkins user for Docker access"
echo -e "  3. Create environment file at /home/ubuntu/rezio-saas/.env"
echo ""
echo -e "${RED}Make sure you have your environment credentials ready!${NC}"
echo ""
read -p "Press Enter to continue..."

# Check if running with sudo/root for some commands
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Don't run this script with sudo!${NC}"
    echo -e "${YELLOW}The script will ask for sudo when needed.${NC}"
    exit 1
fi

# Step 1: Check and Install Docker
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 1: Docker Installation${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is already installed${NC}"
    docker --version
else
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    # Download and install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    echo -e "${GREEN}✓ Docker installed successfully${NC}"
    docker --version
fi

# Step 2: Configure Docker Permissions
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 2: Docker Permissions${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

echo -e "${YELLOW}Adding users to docker group...${NC}"

# Add jenkins user to docker group
if id "jenkins" &>/dev/null; then
    sudo usermod -aG docker jenkins
    echo -e "${GREEN}✓ Added jenkins user to docker group${NC}"
else
    echo -e "${RED}⚠ Jenkins user not found (Jenkins might not be installed)${NC}"
fi

# Add current user to docker group
sudo usermod -aG docker $USER
echo -e "${GREEN}✓ Added $USER to docker group${NC}"

# Restart Docker
echo -e "${YELLOW}Restarting Docker service...${NC}"
sudo systemctl restart docker
echo -e "${GREEN}✓ Docker service restarted${NC}"

# Step 3: Restart Jenkins
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 3: Restart Jenkins${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

if sudo systemctl is-active --quiet jenkins; then
    echo -e "${YELLOW}Restarting Jenkins...${NC}"
    sudo systemctl restart jenkins
    echo -e "${GREEN}✓ Jenkins restarted (wait 2-3 minutes for it to be fully ready)${NC}"
else
    echo -e "${RED}⚠ Jenkins service not found or not running${NC}"
    echo -e "${YELLOW}You may need to install Jenkins first${NC}"
fi

# Step 4: Create Environment File
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 4: Create Environment File${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

ENV_DIR="/home/ubuntu/rezio-saas"
ENV_FILE="$ENV_DIR/.env"

# Create directory
mkdir -p $ENV_DIR
echo -e "${GREEN}✓ Created directory: $ENV_DIR${NC}"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠ Environment file already exists at $ENV_FILE${NC}"
    read -p "Do you want to overwrite it? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo -e "${YELLOW}Skipping environment file creation${NC}"
    else
        mv $ENV_FILE ${ENV_FILE}.backup
        echo -e "${GREEN}✓ Existing .env backed up to ${ENV_FILE}.backup${NC}"
    fi
fi

if [ ! -f "$ENV_FILE" ] || [ "$overwrite" = "yes" ]; then
    echo ""
    echo -e "${YELLOW}Now let's create your environment file...${NC}"
    echo ""
    
    # Collect Database URL
    echo -e "${CYAN}Database Configuration (Neon):${NC}"
    read -p "Paste your DATABASE_URL: " DATABASE_URL
    
    # Remove problematic parameters
    if [[ "$DATABASE_URL" == *"channel_binding=require"* ]]; then
        DATABASE_URL=$(echo "$DATABASE_URL" | sed 's/&channel_binding=require//g')
        echo -e "${YELLOW}⚠ Removed channel_binding parameter (can cause issues)${NC}"
    fi
    
    # Collect Clerk Keys
    echo ""
    echo -e "${CYAN}Clerk Authentication:${NC}"
    read -p "Paste your NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: " CLERK_PUB_KEY
    read -p "Paste your CLERK_SECRET_KEY: " CLERK_SECRET_KEY
    
    # Remove trailing $ if present (common copy-paste error)
    CLERK_PUB_KEY=$(echo "$CLERK_PUB_KEY" | sed 's/\$$//')
    
    # Collect Cloudinary Credentials
    echo ""
    echo -e "${CYAN}Cloudinary Configuration:${NC}"
    read -p "Paste your CLOUDINARY_CLOUD_NAME: " CLOUDINARY_CLOUD_NAME
    read -p "Paste your CLOUDINARY_UPLOAD_PRESET [rezio_uploads]: " CLOUDINARY_PRESET
    CLOUDINARY_PRESET=${CLOUDINARY_PRESET:-rezio_uploads}
    read -p "Paste your CLOUDINARY_API_KEY: " CLOUDINARY_API_KEY
    read -p "Paste your CLOUDINARY_API_SECRET: " CLOUDINARY_API_SECRET
    
    # Create .env file
    cat > $ENV_FILE << EOF
# Database
DATABASE_URL="$DATABASE_URL"

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$CLERK_PUB_KEY"
CLERK_SECRET_KEY="$CLERK_SECRET_KEY"

# Cloudinary
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="$CLOUDINARY_CLOUD_NAME"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="$CLOUDINARY_PRESET"
CLOUDINARY_API_KEY="$CLOUDINARY_API_KEY"
CLOUDINARY_API_SECRET="$CLOUDINARY_API_SECRET"

# Application
NODE_ENV=production
PORT=2000
EOF
    
    # Secure the file
    chmod 600 $ENV_FILE
    
    echo -e "${GREEN}✓ Environment file created at $ENV_FILE${NC}"
    echo -e "${GREEN}✓ File permissions set to 600 (secure)${NC}"
fi

# Step 5: Verification
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 5: Verification${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

echo ""
echo -e "${YELLOW}Verifying installation...${NC}"
echo ""

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker: $(docker --version)${NC}"
else
    echo -e "${RED}✗ Docker: Not found${NC}"
fi

# Check Docker service
if sudo systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Docker Service: Running${NC}"
else
    echo -e "${RED}✗ Docker Service: Not running${NC}"
fi

# Check Jenkins
if sudo systemctl is-active --quiet jenkins; then
    echo -e "${GREEN}✓ Jenkins Service: Running${NC}"
else
    echo -e "${YELLOW}⚠ Jenkins Service: Not running or not installed${NC}"
fi

# Check environment file
if [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}✓ Environment File: Found at $ENV_FILE${NC}"
    PERMS=$(stat -c "%a" $ENV_FILE 2>/dev/null || stat -f "%A" $ENV_FILE 2>/dev/null)
    echo -e "${GREEN}✓ File Permissions: $PERMS${NC}"
else
    echo -e "${RED}✗ Environment File: Not found${NC}"
fi

# Final Summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ Setup completed!${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo -e "  1. Jenkins is restarting (wait 2-3 minutes)"
echo -e "  2. You may need to log out and back in for docker group changes"
echo -e "  3. Environment file is at: $ENV_FILE"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Wait 2-3 minutes for Jenkins to fully restart"
echo -e "  2. Go to Jenkins: http://$(curl -s ifconfig.me):8080"
echo -e "  3. Click on your pipeline job"
echo -e "  4. Click 'Build Now'"
echo ""
echo -e "${GREEN}Your deployment should now work! 🚀${NC}"
echo ""

# Test Docker access (for jenkins user)
echo -e "${YELLOW}Testing Docker access for jenkins user...${NC}"
if id "jenkins" &>/dev/null; then
    if sudo -u jenkins docker ps &>/dev/null; then
        echo -e "${GREEN}✓ Jenkins user can access Docker${NC}"
    else
        echo -e "${YELLOW}⚠ Jenkins user might need to re-login for docker access${NC}"
        echo -e "${YELLOW}  The restart should fix this${NC}"
    fi
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}All done! Check FIX_JENKINS_ISSUES.md for troubleshooting.${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
