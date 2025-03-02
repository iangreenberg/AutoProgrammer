#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Fixing UI issues...${NC}"

# Stop all existing services
echo -e "${YELLOW}1. Stopping all services...${NC}"
pkill -f "node.*vite" || true
pkill -f "node.*gateway.js" || true  
pkill -f "node.*server.js" || true
sleep 2

# Clear npm cache
echo -e "${YELLOW}2. Clearing npm cache...${NC}"
cd autoprogrammer-ui
npm cache clean --force
rm -rf node_modules/.vite

# Restart services in the correct order
echo -e "${YELLOW}3. Starting AI Service...${NC}"
cd ../autoprogrammer-ai-service
NODE_ENV=development npm run dev > ../ai-service.log 2>&1 &
AI_PID=$!
echo -e "${GREEN}✓ AI Service started with PID $AI_PID${NC}"
sleep 2

echo -e "${YELLOW}4. Starting API Gateway...${NC}"
cd ../autoprogrammer-api
NODE_ENV=development npm run dev > ../api-gateway.log 2>&1 &
API_PID=$!
echo -e "${GREEN}✓ API Gateway started with PID $API_PID${NC}"
sleep 2

echo -e "${YELLOW}5. Starting UI...${NC}"
cd ../autoprogrammer-ui
npm run dev > ../ui.log 2>&1 &
UI_PID=$!
echo -e "${GREEN}✓ UI started with PID $UI_PID${NC}"
sleep 2

echo -e "\n${GREEN}All services have been restarted!${NC}"
echo -e "${YELLOW}Please access the UI at: ${GREEN}http://localhost:5173${NC}"
echo -e "${YELLOW}If it's still not working, try opening in an incognito/private window.${NC}"
echo -e "\n${YELLOW}To check logs:${NC}"
echo -e "  AI Service: ${GREEN}tail -f ai-service.log${NC}"
echo -e "  API Gateway: ${GREEN}tail -f api-gateway.log${NC}"
echo -e "  UI: ${GREEN}tail -f ui.log${NC}"