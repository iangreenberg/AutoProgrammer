#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== AutoProgrammer Port Conflict Resolution Tool =====${NC}"
echo -e "Checking for services using required ports..."

# Check and resolve port conflicts
check_and_kill_port() {
    local port=$1
    local service_name=$2
    
    echo -e "Checking port ${port} for ${service_name}..."
    
    # Get process using the port
    local pid=$(lsof -t -i:${port})
    
    if [ -n "$pid" ]; then
        echo -e "${YELLOW}Found process ${pid} using port ${port}${NC}"
        echo -e "This port is needed for ${service_name}"
        
        read -p "Do you want to kill this process? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "Killing process ${pid}..."
            kill -9 $pid
            echo -e "${GREEN}Process killed. Port ${port} is now available.${NC}"
        else
            echo -e "${RED}Port ${port} still in use. ${service_name} may not start correctly.${NC}"
        fi
    else
        echo -e "${GREEN}Port ${port} is available for ${service_name}.${NC}"
    fi
}

# Check and fix each required port
check_and_kill_port 4000 "API Gateway"
check_and_kill_port 4001 "API Gateway (alternate port)"
check_and_kill_port 5000 "AI Service"
check_and_kill_port 5001 "AI Service (alternate port)"
check_and_kill_port 5173 "Frontend UI"
check_and_kill_port 5174 "Frontend UI (alternate port)"

echo
echo -e "${GREEN}Port conflict check completed.${NC}"
echo -e "You can now start your services with proper port availability."
echo

# Check for running Docker containers that might be using the ports
if command -v docker &> /dev/null; then
    echo "Checking Docker containers..."
    docker ps | grep -E '(4000|4001|5000|5001|5173|5174)'
    
    echo
    echo -e "${YELLOW}If any Docker containers are using required ports, you can stop them with:${NC}"
    echo -e "docker stop <container_id>"
fi 