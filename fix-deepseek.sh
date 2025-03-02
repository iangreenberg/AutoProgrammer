#!/bin/bash

echo "=========================================================="
echo "        Updating DeepSeek API Key"
echo "=========================================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set up the project root for reference
PROJECT_ROOT="$(pwd)"

# First, stop the AI service
echo -e "${YELLOW}Stopping AI Service...${NC}"
pkill -f "node.*server.js" || true
sleep 2

# Force kill any processes on port 5000
pid=$(lsof -ti:5000 2>/dev/null)
if [ ! -z "$pid" ]; then
    echo -e "Killing process $pid using port 5000"
    kill -9 $pid 2>/dev/null || true
    sleep 1
fi

# Verify port is free
if lsof -i:5000 &>/dev/null; then
    echo -e "${RED}Port 5000 is still in use. Please check manually with 'lsof -i:5000'${NC}"
    echo -e "You may need to reboot your system if processes are stuck."
    exit 1
else
    echo -e "${GREEN}Port 5000 is free${NC}"
fi

# Change to AI service directory
echo -e "\n${YELLOW}Updating AI Service configuration...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ai-service" || {
    echo -e "${RED}Error: AI Service directory not found at ${PROJECT_ROOT}/autoprogrammer-ai-service${NC}"
    exit 1
}

# Create .env file with the new API key
echo -e "Creating .env file with new DeepSeek API key..."
cat > ".env" << 'EOL'
NODE_ENV=development
PORT=5000
GATEWAY_URL=http://localhost:4000
DEEPSEEK_MODEL=deepseek-coder-33b-instruct
DEEPSEEK_API_KEY=sk-059ceddc99ad4a5fbd56b6c090d8fab2
EOL
echo -e "${GREEN}API key updated${NC}"

# Start AI service again
echo -e "\n${YELLOW}Starting AI Service...${NC}"
NODE_ENV=development npm run dev > "${PROJECT_ROOT}/ai-debug.log" 2>&1 &
AI_PID=$!
echo -e "${GREEN}AI Service started with PID $AI_PID${NC}"
sleep 3

# Check if AI Service is running
if ! ps -p $AI_PID > /dev/null; then
    echo -e "${RED}AI Service failed to start. Check logs: ${PROJECT_ROOT}/ai-debug.log${NC}"
    tail -n 20 "${PROJECT_ROOT}/ai-debug.log"
else
    echo -e "${GREEN}AI Service is running${NC}"
    echo -e "\n${BLUE}=========================================================${NC}"
    echo -e "${BLUE}                 DeepSeek API Key Updated                ${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "\nThe AI Service has been restarted with the new DeepSeek API key."
    echo -e "You should now be able to use the AI features of the application."
    echo -e "\nTo test, try visiting: ${GREEN}http://localhost:5173/${NC}"
    echo -e "And asking the AI a question like 'Create a simple REST API'"
fi 