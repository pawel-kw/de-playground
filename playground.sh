#!/bin/bash

# Data Engineering Playground Helper Script
# This script provides convenient commands for managing the playground

set -e

COMPOSE_FILE="docker-compose.yml"
PROJECT_NAME="de-playground"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=== Data Engineering Playground ===${NC}"
    echo
}

print_usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start       Start all services"
    echo "  stop        Stop all services"
    echo "  restart     Restart all services"
    echo "  status      Show service status"
    echo "  logs        Show logs for all services"
    echo "  logs [svc]  Show logs for specific service"
    echo "  shell       Access the development box shell"
    echo "  psql        Connect to PostgreSQL"
    echo "  backup      Backup PostgreSQL database"
    echo "  restore     Restore PostgreSQL database from backup"
    echo "  clean       Stop and remove all containers and volumes"
    echo "  update      Pull latest images and restart"
    echo "  help        Show this help message"
}

start_services() {
    echo -e "${GREEN}Starting Data Engineering Playground...${NC}"
    docker-compose up -d
    echo
    echo -e "${GREEN}Services started successfully!${NC}"
    echo
    echo "Access URLs:"
    echo "  PostgreSQL: localhost:5432"
    echo "  pgAdmin:    http://localhost:8080"
    echo
    echo "Run '$0 status' to check service health"
}

stop_services() {
    echo -e "${YELLOW}Stopping Data Engineering Playground...${NC}"
    docker-compose down
    echo -e "${GREEN}Services stopped successfully!${NC}"
}

restart_services() {
    echo -e "${YELLOW}Restarting Data Engineering Playground...${NC}"
    docker-compose restart
    echo -e "${GREEN}Services restarted successfully!${NC}"
}

show_status() {
    echo -e "${BLUE}Service Status:${NC}"
    docker-compose ps
    echo
    echo -e "${BLUE}Health Checks:${NC}"
    docker-compose exec postgres pg_isready -U "${POSTGRES_USER:-deuser}" -d "${POSTGRES_DB:-playground}" 2>/dev/null && \
        echo -e "PostgreSQL: ${GREEN}✓ Healthy${NC}" || \
        echo -e "PostgreSQL: ${RED}✗ Unhealthy${NC}"
}

show_logs() {
    if [ -n "$1" ]; then
        echo -e "${BLUE}Showing logs for service: $1${NC}"
        docker-compose logs -f "$1"
    else
        echo -e "${BLUE}Showing logs for all services:${NC}"
        docker-compose logs -f
    fi
}

access_shell() {
    echo -e "${GREEN}Accessing development box shell...${NC}"
    echo "Tip: Switch to deuser with 'su - deuser'"
    docker-compose exec dev-box bash
}

connect_psql() {
    echo -e "${GREEN}Connecting to PostgreSQL...${NC}"
    echo "Database: ${POSTGRES_DB:-playground}"
    echo "Username: ${POSTGRES_USER:-deuser}"
    echo "Password: ${POSTGRES_PASSWORD:-depassword}"
    echo
    docker-compose exec postgres psql -U "${POSTGRES_USER:-deuser}" -d "${POSTGRES_DB:-playground}"
}

backup_database() {
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    echo -e "${GREEN}Creating database backup: $BACKUP_FILE${NC}"
    docker-compose exec postgres pg_dump -U "${POSTGRES_USER:-deuser}" "${POSTGRES_DB:-playground}" > "$BACKUP_FILE"
    echo -e "${GREEN}Backup created successfully!${NC}"
}

restore_database() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify backup file${NC}"
        echo "Usage: $0 restore <backup_file.sql>"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        echo -e "${RED}Error: Backup file '$1' not found${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Restoring database from: $1${NC}"
    echo -e "${RED}Warning: This will overwrite existing data!${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose exec -T postgres psql -U "${POSTGRES_USER:-deuser}" "${POSTGRES_DB:-playground}" < "$1"
        echo -e "${GREEN}Database restored successfully!${NC}"
    else
        echo "Restore cancelled."
    fi
}

clean_all() {
    echo -e "${RED}Warning: This will remove all containers and volumes (including data)!${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cleaning up all resources...${NC}"
        docker-compose down -v --remove-orphans
        echo -e "${GREEN}Cleanup completed!${NC}"
    else
        echo "Cleanup cancelled."
    fi
}

update_services() {
    echo -e "${BLUE}Updating services...${NC}"
    docker-compose pull
    docker-compose up -d
    echo -e "${GREEN}Services updated successfully!${NC}"
}

# Main script logic
print_header

case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    shell)
        access_shell
        ;;
    psql)
        connect_psql
        ;;
    backup)
        backup_database
        ;;
    restore)
        restore_database "$2"
        ;;
    clean)
        clean_all
        ;;
    update)
        update_services
        ;;
    help|--help|-h)
        print_usage
        ;;
    "")
        print_usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo
        print_usage
        exit 1
        ;;
esac
