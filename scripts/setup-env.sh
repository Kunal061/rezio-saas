#!/bin/bash

###############################################################################
# Rezio SaaS - Interactive Environment Setup
# This script helps you create .env files with your own credentials
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Rezio SaaS - Environment Setup Wizard${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}This wizard will help you create your .env file${NC}"
echo -e "${YELLOW}You'll need accounts at:${NC}"
echo -e "  1. ${BLUE}Neon.tech${NC} (Database) - FREE"
echo -e "  2. ${BLUE}Clerk.com${NC} (Authentication) - FREE"
echo -e "  3. ${BLUE}Cloudinary.com${NC} (Media Storage) - FREE"
echo ""
echo -e "${GREEN}Press Enter to continue...${NC}"
read

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠ Warning: .env file already exists!${NC}"
    read -p "Do you want to overwrite it? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo -e "${RED}Setup cancelled.${NC}"
        exit 0
    fi
    mv .env .env.backup
    echo -e "${GREEN}✓ Existing .env backed up to .env.backup${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 1: Database Configuration (Neon)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Instructions:${NC}"
echo -e "  1. Go to: ${BLUE}https://neon.tech${NC}"
echo -e "  2. Sign up (FREE) and create a new project"
echo -e "  3. Copy the connection string"
echo -e "     Example: postgresql://user:pass@ep-xxx.neon.tech:5432/dbname"
echo ""
read -p "Paste your DATABASE_URL: " DATABASE_URL

if [ -z "$DATABASE_URL" ]; then
    echo -e "${RED}✗ DATABASE_URL cannot be empty!${NC}"
    exit 1
fi

# Add schema if not present
if [[ ! "$DATABASE_URL" == *"?schema="* ]]; then
    DATABASE_URL="${DATABASE_URL}?schema=public"
    echo -e "${GREEN}✓ Added '?schema=public' to your DATABASE_URL${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 2: Clerk Authentication${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Instructions:${NC}"
echo -e "  1. Go to: ${BLUE}https://clerk.com${NC}"
echo -e "  2. Sign up (FREE) and create a new application"
echo -e "  3. Go to 'API Keys' section"
echo -e "  4. Copy both keys (they start with pk_test_ and sk_test_)"
echo ""
read -p "Paste your NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: " CLERK_PUB_KEY

if [ -z "$CLERK_PUB_KEY" ]; then
    echo -e "${RED}✗ Clerk publishable key cannot be empty!${NC}"
    exit 1
fi

read -p "Paste your CLERK_SECRET_KEY: " CLERK_SECRET_KEY

if [ -z "$CLERK_SECRET_KEY" ]; then
    echo -e "${RED}✗ Clerk secret key cannot be empty!${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 3: Cloudinary Media Storage${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Instructions:${NC}"
echo -e "  1. Go to: ${BLUE}https://cloudinary.com${NC}"
echo -e "  2. Sign up (FREE)"
echo -e "  3. From Dashboard, copy:"
echo -e "     - Cloud Name"
echo -e "     - API Key"
echo -e "     - API Secret (click 'reveal')"
echo -e "  4. Create Upload Preset:"
echo -e "     Settings → Upload → Add upload preset"
echo -e "     Name: ${GREEN}rezio_uploads${NC}"
echo -e "     Mode: ${GREEN}Unsigned${NC} (IMPORTANT!)"
echo -e "     Folder: ${GREEN}video-uploads${NC}"
echo ""
read -p "Paste your CLOUDINARY_CLOUD_NAME: " CLOUDINARY_CLOUD_NAME

if [ -z "$CLOUDINARY_CLOUD_NAME" ]; then
    echo -e "${RED}✗ Cloudinary cloud name cannot be empty!${NC}"
    exit 1
fi

read -p "Paste your CLOUDINARY_API_KEY: " CLOUDINARY_API_KEY

if [ -z "$CLOUDINARY_API_KEY" ]; then
    echo -e "${RED}✗ Cloudinary API key cannot be empty!${NC}"
    exit 1
fi

read -p "Paste your CLOUDINARY_API_SECRET: " CLOUDINARY_API_SECRET

if [ -z "$CLOUDINARY_API_SECRET" ]; then
    echo -e "${RED}✗ Cloudinary API secret cannot be empty!${NC}"
    exit 1
fi

read -p "Enter your upload preset name [rezio_uploads]: " CLOUDINARY_PRESET
CLOUDINARY_PRESET=${CLOUDINARY_PRESET:-rezio_uploads}

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Step 4: Application Settings${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
read -p "Environment (development/production) [development]: " NODE_ENV
NODE_ENV=${NODE_ENV:-development}

if [ "$NODE_ENV" = "production" ]; then
    PORT=2000
else
    PORT=3000
fi
read -p "Port [$PORT]: " PORT_INPUT
PORT=${PORT_INPUT:-$PORT}

# Create .env file
echo ""
echo -e "${YELLOW}Creating .env file...${NC}"

cat > .env << EOF
# Database Configuration
DATABASE_URL="$DATABASE_URL"

# Clerk Authentication
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$CLERK_PUB_KEY"
CLERK_SECRET_KEY="$CLERK_SECRET_KEY"

# Cloudinary Configuration
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="$CLOUDINARY_CLOUD_NAME"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="$CLOUDINARY_PRESET"
CLOUDINARY_API_KEY="$CLOUDINARY_API_KEY"
CLOUDINARY_API_SECRET="$CLOUDINARY_API_SECRET"

# Application Settings
NODE_ENV=$NODE_ENV
PORT=$PORT
EOF

echo -e "${GREEN}✓ .env file created successfully!${NC}"

# Secure the file
chmod 600 .env
echo -e "${GREEN}✓ File permissions set to secure (600)${NC}"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Next Steps${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}1. Initialize database:${NC}"
echo -e "   ${GREEN}npm install${NC}"
echo -e "   ${GREEN}npx prisma generate${NC}"
echo -e "   ${GREEN}npx prisma db push${NC}"
echo ""
echo -e "${YELLOW}2. Start development server:${NC}"
echo -e "   ${GREEN}npm run dev${NC}"
echo ""
echo -e "${YELLOW}3. Open browser:${NC}"
echo -e "   ${BLUE}http://localhost:$PORT${NC}"
echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""

# Offer to run initialization
read -p "Do you want to initialize the database now? (yes/no): " init_db
if [ "$init_db" = "yes" ]; then
    echo ""
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
    
    echo ""
    echo -e "${YELLOW}Generating Prisma client...${NC}"
    npx prisma generate
    
    echo ""
    echo -e "${YELLOW}Pushing schema to database...${NC}"
    npx prisma db push
    
    echo ""
    echo -e "${GREEN}✓ Database initialized successfully!${NC}"
    echo ""
    echo -e "${GREEN}You can now run: npm run dev${NC}"
else
    echo ""
    echo -e "${YELLOW}Remember to run these commands:${NC}"
    echo -e "  ${GREEN}npm install${NC}"
    echo -e "  ${GREEN}npx prisma generate${NC}"
    echo -e "  ${GREEN}npx prisma db push${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Need help? Check: SETUP_FROM_SCRATCH.md${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
