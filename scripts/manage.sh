#!/bin/bash

###############################################################################
# Rezio SaaS - Quick Commands Helper Script
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONTAINER_NAME="rezio-saas-container"
APP_PORT="2000"

show_menu() {
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}    Rezio SaaS - Management Menu${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}1.${NC} Show container status"
    echo -e "${BLUE}2.${NC} View application logs"
    echo -e "${BLUE}3.${NC} Follow logs in real-time"
    echo -e "${BLUE}4.${NC} Restart container"
    echo -e "${BLUE}5.${NC} Stop container"
    echo -e "${BLUE}6.${NC} Start container"
    echo -e "${BLUE}7.${NC} Check health"
    echo -e "${BLUE}8.${NC} Enter container shell"
    echo -e "${BLUE}9.${NC} View Docker images"
    echo -e "${BLUE}10.${NC} Clean up Docker resources"
    echo -e "${BLUE}11.${NC} Run Prisma migrations"
    echo -e "${BLUE}12.${NC} View Prisma migration status"
    echo -e "${BLUE}0.${NC} Exit"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
}

container_status() {
    echo -e "${YELLOW}Container Status:${NC}"
    docker ps -a -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

view_logs() {
    echo -e "${YELLOW}Last 50 lines of logs:${NC}"
    docker logs --tail 50 $CONTAINER_NAME
}

follow_logs() {
    echo -e "${YELLOW}Following logs (Ctrl+C to stop):${NC}"
    docker logs -f $CONTAINER_NAME
}

restart_container() {
    echo -e "${YELLOW}Restarting container...${NC}"
    docker restart $CONTAINER_NAME
    echo -e "${GREEN}✓ Container restarted${NC}"
}

stop_container() {
    echo -e "${YELLOW}Stopping container...${NC}"
    docker stop $CONTAINER_NAME
    echo -e "${GREEN}✓ Container stopped${NC}"
}

start_container() {
    echo -e "${YELLOW}Starting container...${NC}"
    docker start $CONTAINER_NAME
    echo -e "${GREEN}✓ Container started${NC}"
}

health_check() {
    echo -e "${YELLOW}Checking application health...${NC}"
    if curl -f http://localhost:$APP_PORT/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Application is healthy and responding${NC}"
        echo -e "${GREEN}URL: http://localhost:$APP_PORT${NC}"
    else
        echo -e "${RED}✗ Application is not responding${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Docker health status:${NC}"
    docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null || echo "No health check configured"
}

enter_shell() {
    echo -e "${YELLOW}Entering container shell...${NC}"
    docker exec -it $CONTAINER_NAME sh
}

view_images() {
    echo -e "${YELLOW}Docker Images:${NC}"
    docker images rezio-saas --format "table {{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}"
}

cleanup_docker() {
    echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
    echo -e "${YELLOW}This will remove:${NC}"
    echo -e "  - Stopped containers"
    echo -e "  - Unused images"
    echo -e "  - Unused networks"
    echo -e "  - Build cache"
    echo ""
    read -p "Continue? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        docker system prune -a -f
        echo -e "${GREEN}✓ Cleanup completed${NC}"
    else
        echo -e "${YELLOW}Cleanup cancelled${NC}"
    fi
}

run_migrations() {
    echo -e "${YELLOW}Running Prisma migrations...${NC}"
    docker exec $CONTAINER_NAME npx prisma migrate deploy
    echo -e "${GREEN}✓ Migrations completed${NC}"
}

migration_status() {
    echo -e "${YELLOW}Prisma Migration Status:${NC}"
    docker exec $CONTAINER_NAME npx prisma migrate status
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice [0-12]: " choice
    
    case $choice in
        1) container_status ;;
        2) view_logs ;;
        3) follow_logs ;;
        4) restart_container ;;
        5) stop_container ;;
        6) start_container ;;
        7) health_check ;;
        8) enter_shell ;;
        9) view_images ;;
        10) cleanup_docker ;;
        11) run_migrations ;;
        12) migration_status ;;
        0) 
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done
