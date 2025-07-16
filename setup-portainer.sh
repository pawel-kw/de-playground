#!/bin/bash

# Portainer Volume Initialization Script
# This script helps set up the necessary files in Docker volumes for Portainer deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

STACK_NAME="de-playground"

print_header() {
    echo -e "${BLUE}=== Portainer Volume Setup ===${NC}"
    echo "This script will initialize Docker volumes with necessary files for Portainer deployment."
    echo
}

check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
}

create_init_scripts_volume() {
    echo -e "${BLUE}Setting up init-scripts volume...${NC}"
    
    # Create a temporary container to copy files
    docker run --rm -v ${STACK_NAME}_init_scripts:/target -v "$(pwd)/init-scripts":/source alpine:latest sh -c "
        cp -r /source/* /target/ 2>/dev/null || echo 'No init scripts found, creating empty volume'
        ls -la /target/
    "
    
    echo -e "${GREEN}✓ Init scripts volume created${NC}"
}

create_workspace_volume() {
    echo -e "${BLUE}Setting up workspace volume...${NC}"
    
    # Create workspace volume and copy sample files
    docker run --rm -v ${STACK_NAME}_workspace_data:/target -v "$(pwd)/workspace":/source alpine:latest sh -c "
        cp -r /source/* /target/ 2>/dev/null || echo 'No workspace files found, creating empty volume'
        chmod -R 755 /target/
        ls -la /target/
    "
    
    echo -e "${GREEN}✓ Workspace volume created${NC}"
}

show_portainer_instructions() {
    echo
    echo -e "${YELLOW}=== Portainer Deployment Instructions ===${NC}"
    echo
    echo "1. Log into your Portainer instance"
    echo "2. Go to 'Stacks' and click 'Add stack'"
    echo "3. Choose 'Git Repository' or 'Upload' method:"
    echo
    echo -e "${BLUE}Option A - Git Repository:${NC}"
    echo "   - Repository URL: https://github.com/pawel-kw/de-playground"
    echo "   - Compose path: docker-compose.yml"
    echo
    echo -e "${BLUE}Option B - Upload:${NC}"
    echo "   - Upload the docker-compose.yml file"
    echo
    echo "4. Set the stack name: ${STACK_NAME}"
    echo
    echo "5. Add these environment variables:"
    echo -e "${GREEN}"
    cat .env.portainer | sed 's/^/   /'
    echo -e "${NC}"
    echo
    echo "6. Deploy the stack"
    echo
    echo -e "${BLUE}Access URLs (after deployment):${NC}"
    echo "   - PostgreSQL: <server-ip>:5432"
    echo "   - pgAdmin: http://<server-ip>:8082"
    echo "   - File Browser: http://<server-ip>:8083"
    echo
    echo -e "${YELLOW}Note:${NC} Replace <server-ip> with your actual server IP address"
}

show_volume_management() {
    echo
    echo -e "${YELLOW}=== Volume Management ===${NC}"
    echo
    echo "To backup volumes:"
    echo "  docker run --rm -v ${STACK_NAME}_postgres_data:/source -v \$(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /source ."
    echo
    echo "To restore volumes:"
    echo "  docker run --rm -v ${STACK_NAME}_postgres_data:/target -v \$(pwd):/backup alpine tar xzf /backup/postgres_backup.tar.gz -C /target"
    echo
    echo "To list all volumes:"
    echo "  docker volume ls | grep ${STACK_NAME}"
    echo
    echo "To remove all volumes (WARNING: destroys data):"
    echo "  docker volume rm \$(docker volume ls -q | grep ${STACK_NAME})"
}

cleanup_existing_volumes() {
    echo -e "${YELLOW}Checking for existing volumes...${NC}"
    
    existing_volumes=$(docker volume ls -q | grep "^${STACK_NAME}_" || true)
    
    if [ ! -z "$existing_volumes" ]; then
        echo "Found existing volumes:"
        echo "$existing_volumes"
        echo
        read -p "Do you want to remove existing volumes? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$existing_volumes" | xargs docker volume rm
            echo -e "${GREEN}✓ Existing volumes removed${NC}"
        else
            echo "Keeping existing volumes. They will be used by the new stack."
        fi
    fi
}

main() {
    print_header
    check_requirements
    
    echo "Stack name: ${STACK_NAME}"
    echo
    
    # Ask user if they want to set up volumes
    read -p "Do you want to initialize Docker volumes for Portainer? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping volume initialization."
    else
        cleanup_existing_volumes
        
        if [ -d "init-scripts" ]; then
            create_init_scripts_volume
        else
            echo -e "${YELLOW}Warning: init-scripts directory not found${NC}"
        fi
        
        if [ -d "workspace" ]; then
            create_workspace_volume
        else
            echo -e "${YELLOW}Warning: workspace directory not found${NC}"
        fi
    fi
    
    show_portainer_instructions
    show_volume_management
    
    echo
    echo -e "${GREEN}Setup complete! You can now deploy the stack in Portainer.${NC}"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo "Initialize Docker volumes and show Portainer deployment instructions"
        exit 0
        ;;
    *)
        main
        ;;
esac
