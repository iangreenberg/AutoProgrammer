#!/bin/bash

# AutoProgrammer Microservices Startup Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a port is in use
is_port_in_use() {
  lsof -i:"$1" >/dev/null 2>&1
  return $?
}

echo -e "${GREEN}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│        AutoProgrammer Microservices Startup     │${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────┘${NC}"
echo

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed. Please install Node.js to continue.${NC}"
    exit 1
fi

BASEDIR="$(pwd)"

# Ensure .env files exist for both services
if [ ! -f "$BASEDIR/autoprogrammer-api/.env" ]; then
    echo -e "${YELLOW}Creating API Gateway .env file from example...${NC}"
    cp "$BASEDIR/autoprogrammer-api/.env.example" "$BASEDIR/autoprogrammer-api/.env"
    echo -e "${YELLOW}Please update API Gateway .env file with appropriate values.${NC}"
fi

if [ ! -f "$BASEDIR/autoprogrammer-ai-service/.env" ]; then
    echo -e "${YELLOW}Creating AI Service .env file from example...${NC}"
    cp "$BASEDIR/autoprogrammer-ai-service/.env.example" "$BASEDIR/autoprogrammer-ai-service/.env"
    echo -e "${YELLOW}Please update AI Service .env file with appropriate values.${NC}"
fi

# Check if ports are already in use
if is_port_in_use 4000; then
    echo -e "${RED}Port 4000 is already in use. API Gateway cannot start.${NC}"
    echo -e "${YELLOW}Please stop any service using port 4000 and try again.${NC}"
    exit 1
fi

if is_port_in_use 5000; then
    echo -e "${RED}Port 5000 is already in use. AI Processing Service cannot start.${NC}"
    echo -e "${YELLOW}Please stop any service using port 5000 and try again.${NC}"
    exit 1
fi

if is_port_in_use 5173 && is_port_in_use 5174; then
    echo -e "${RED}Both ports 5173 and 5174 are in use. UI service cannot start.${NC}"
    echo -e "${YELLOW}Please stop any service using these ports and try again.${NC}"
    exit 1
fi

# 1. Install dependencies for all services
echo -e "${CYAN}Installing dependencies for API Gateway...${NC}"
cd "$BASEDIR/autoprogrammer-api" && npm install

echo -e "${CYAN}Installing dependencies for AI Processing Service...${NC}"
cd "$BASEDIR/autoprogrammer-ai-service" && npm install

if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "${CYAN}Installing dependencies for UI...${NC}"
    cd "$BASEDIR/autoprogrammer-ui" && npm install
fi

# 2. Start AI Processing Service in the background
echo -e "${CYAN}Starting AI Processing Service on port 5000...${NC}"
cd "$BASEDIR/autoprogrammer-ai-service" && NODE_ENV=development nohup npm run dev > "$BASEDIR/ai-service.log" 2>&1 &
AI_SERVICE_PID=$!

# Wait a moment to ensure the service starts
sleep 2

# Check if AI service started successfully
if ! is_port_in_use 5000; then
    echo -e "${RED}Failed to start AI Processing Service.${NC}"
    echo -e "${YELLOW}Check logs at: $BASEDIR/ai-service.log${NC}"
    exit 1
fi

# 3. Start API Gateway in the background
echo -e "${CYAN}Starting API Gateway on port 4000...${NC}"
cd "$BASEDIR/autoprogrammer-api" && NODE_ENV=development nohup npm run dev > "$BASEDIR/api-gateway.log" 2>&1 &
API_GATEWAY_PID=$!

# Wait a moment to ensure the service starts
sleep 2

# Check if API Gateway started successfully
if ! is_port_in_use 4000; then
    echo -e "${RED}Failed to start API Gateway.${NC}"
    echo -e "${YELLOW}Check logs at: $BASEDIR/api-gateway.log${NC}"
    exit 1
fi

# 4. Start UI if it exists
if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "${CYAN}Starting UI service...${NC}"
    cd "$BASEDIR/autoprogrammer-ui" && nohup npm run dev > "$BASEDIR/ui.log" 2>&1 &
    UI_PID=$!
    
    # Wait a moment to ensure the service starts
    sleep 2
    
    # Check if UI started successfully (on either port)
    if ! is_port_in_use 5173 && ! is_port_in_use 5174; then
        echo -e "${RED}Failed to start UI service.${NC}"
        echo -e "${YELLOW}Check logs at: $BASEDIR/ui.log${NC}"
    else
        UI_PORT=$(is_port_in_use 5173 && echo "5173" || echo "5174")
        echo -e "${GREEN}UI service started on port $UI_PORT${NC}"
    fi
fi

echo
echo -e "${GREEN}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│        AutoProgrammer Services Started          │${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│  API Gateway: http://localhost:4000             │${NC}"
echo -e "${GREEN}│  AI Service:  http://localhost:5000             │${NC}"
if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    UI_PORT=$(is_port_in_use 5173 && echo "5173" || echo "5174")
    echo -e "${GREEN}│  UI:         http://localhost:$UI_PORT             │${NC}"
fi
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│  Logs:                                          │${NC}"
echo -e "${GREEN}│  - API Gateway: $BASEDIR/api-gateway.log        │${NC}"
echo -e "${GREEN}│  - AI Service:  $BASEDIR/ai-service.log         │${NC}"
if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "${GREEN}│  - UI:         $BASEDIR/ui.log                │${NC}"
fi
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│  Press Ctrl+C to stop all services              │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────┘${NC}"

# Create a trap to gracefully shut down services on script exit
trap 'echo -e "${YELLOW}Stopping all services...${NC}"; kill $AI_SERVICE_PID $API_GATEWAY_PID $UI_PID 2>/dev/null; exit' INT TERM

# Wait for user to press Ctrl+C
wait 