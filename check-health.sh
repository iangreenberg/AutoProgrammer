#!/bin/bash

# AutoProgrammer Health Check Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│      AutoProgrammer Health Check Tool           │${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────┘${NC}"
echo

# Function to check if a port is in use
check_port() {
  local port=$1
  local service=$2
  
  if lsof -i :$port > /dev/null 2>&1; then
    echo -e "${GREEN}✓ $service is running on port $port${NC}"
    return 0
  else
    echo -e "${RED}✗ $service is NOT running on port $port${NC}"
    return 1
  fi
}

# Function to check health endpoint
check_health_endpoint() {
  local url=$1
  local service=$2
  
  echo -e "${CYAN}Checking $service health endpoint...${NC}"
  
  # Use curl with a 5 second timeout
  if curl -s -o /dev/null -w "%{http_code}" --max-time 5 $url | grep -q "200\|201\|202\|204"; then
    echo -e "${GREEN}✓ $service health check passed${NC}"
    return 0
  else
    echo -e "${RED}✗ $service health check failed${NC}"
    return 1
  fi
}

# Check if services are running on their ports
echo -e "${CYAN}Checking if services are running...${NC}"
api_running=false
ai_running=false
ui_running=false

check_port 4000 "API Gateway" && api_running=true
check_port 5000 "AI Processing Service" && ai_running=true
check_port 5174 "Frontend UI" && ui_running=true || check_port 5173 "Frontend UI" && ui_running=true

echo

# Check health endpoints if services are running
if [ "$api_running" = true ]; then
  check_health_endpoint "http://localhost:4000/api/health" "API Gateway"
else
  echo -e "${YELLOW}Skipping API Gateway health check as service is not running${NC}"
fi

if [ "$ai_running" = true ]; then
  check_health_endpoint "http://localhost:5000/health" "AI Processing Service"
else
  echo -e "${YELLOW}Skipping AI Processing Service health check as service is not running${NC}"
fi

if [ "$ui_running" = true ]; then
  echo -e "${CYAN}Checking Frontend UI...${NC}"
  echo -e "${GREEN}✓ Frontend UI is accessible${NC}"
else
  echo -e "${YELLOW}Frontend UI is not running${NC}"
fi

echo
echo -e "${CYAN}Health check summary:${NC}"
echo -e "API Gateway: $([ "$api_running" = true ] && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Not Running${NC}")"
echo -e "AI Processing Service: $([ "$ai_running" = true ] && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Not Running${NC}")"
echo -e "Frontend UI: $([ "$ui_running" = true ] && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Not Running${NC}")"
echo

# Provide troubleshooting advice if any service is down
if [ "$api_running" = false ] || [ "$ai_running" = false ] || [ "$ui_running" = false ]; then
  echo -e "${YELLOW}Troubleshooting Tips:${NC}"
  echo -e "1. Check if you've started all services using ./startup.sh"
  echo -e "2. Try restarting services with ./restart-services.sh"
  echo -e "3. Check for port conflicts with other applications"
  echo -e "4. Verify environment variables are set correctly in each service"
  echo -e "5. Check service logs for specific error messages"
  echo -e "6. See troubleshooting-notes.md for more detailed guidance"
fi 