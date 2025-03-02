#!/bin/bash

# AutoProgrammer Microservices Restart Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│      AutoProgrammer Microservices Restart       │${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────┘${NC}"
echo

# Function to kill process by port
kill_process_by_port() {
  local port=$1
  local pid=$(lsof -ti:$port)
  
  if [ -n "$pid" ]; then
    echo -e "${YELLOW}Stopping process on port $port (PID: $pid)...${NC}"
    kill -9 $pid 2>/dev/null
    sleep 1
    echo -e "${GREEN}Process on port $port stopped.${NC}"
    return 0
  else
    echo -e "${CYAN}No process found on port $port.${NC}"
    return 1
  fi
}

# Stop all services
echo -e "${CYAN}Stopping all AutoProgrammer services...${NC}"

# Try to kill services by port
kill_process_by_port 4000  # API Gateway
kill_process_by_port 5000  # AI Service
kill_process_by_port 5173  # UI (Vite default)
kill_process_by_port 5174  # UI (Vite alternate)

# Additional cleanup - find any node processes with our service names and kill them
echo -e "${CYAN}Cleaning up any remaining service processes...${NC}"
pkill -f "autoprogrammer-api" 2>/dev/null
pkill -f "autoprogrammer-ai-service" 2>/dev/null
pkill -f "autoprogrammer-ui" 2>/dev/null

# Wait a moment to ensure all processes are stopped
sleep 2

# Clean up log files
echo -e "${CYAN}Cleaning up log files...${NC}"
rm -f api-gateway.log ai-service.log ui.log

# Start the services again using the startup script
echo -e "${CYAN}Starting services again...${NC}"
echo

# Make startup.sh executable if it's not already
chmod +x ./startup.sh

# Run the startup script
./startup.sh 