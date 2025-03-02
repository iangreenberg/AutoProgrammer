#!/bin/bash

echo "=========================================================="
echo "        Updating React to Stable Version (18.2.0)"
echo "=========================================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set up the project root for reference
PROJECT_ROOT="$(pwd)"

# Stop UI service first
echo -e "${YELLOW}Stopping UI Service...${NC}"
pkill -f "node.*vite" || true
sleep 2

# Free the UI port
for port in 5173 5174; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo -e "Killing process $pid using port $port"
        kill -9 $pid 2>/dev/null || true
        sleep 1
    fi
done

# Change to UI directory
echo -e "\n${YELLOW}Updating React version...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ui" || {
    echo -e "${RED}Error: UI directory not found at ${PROJECT_ROOT}/autoprogrammer-ui${NC}"
    exit 1
}

# Update package.json directly to use stable React 18
echo -e "Updating package.json to use React 18.2.0..."
sed -i '' 's/"react": "\^19.0.0"/"react": "^18.2.0"/g' package.json
sed -i '' 's/"react-dom": "\^19.0.0"/"react-dom": "^18.2.0"/g' package.json
echo -e "${GREEN}package.json updated${NC}"

# Clean and reinstall
echo -e "Removing node_modules and reinstalling dependencies..."
rm -rf node_modules
rm -rf .vite
npm cache clean --force
npm install
echo -e "${GREEN}Dependencies reinstalled${NC}"

# Start UI service again
echo -e "\n${YELLOW}Starting UI Service...${NC}"
npm run dev > "${PROJECT_ROOT}/ui-debug.log" 2>&1 &
UI_PID=$!
echo -e "${GREEN}UI Service started with PID $UI_PID${NC}"
sleep 5

# Check if UI is running
if ! ps -p $UI_PID > /dev/null; then
    echo -e "${RED}UI Service failed to start. Check logs: ${PROJECT_ROOT}/ui-debug.log${NC}"
    tail -n 20 "${PROJECT_ROOT}/ui-debug.log"
else
    # Get the actual port being used
    if grep -q "Port 5173 is in use" "${PROJECT_ROOT}/ui-debug.log"; then
        UI_PORT=5174
    else
        UI_PORT=5173
    fi
    
    echo -e "${GREEN}UI Service is running on port $UI_PORT${NC}"
    
    echo -e "\n${BLUE}=========================================================${NC}"
    echo -e "${BLUE}                 React Version Update Complete                ${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "\nThe React version has been downgraded from 19.0.0 (experimental) to 18.2.0 (stable)."
    echo -e "This should fix compatibility issues causing the blank page."
    echo -e "\nVisit the UI at: ${GREEN}http://localhost:$UI_PORT/${NC}"
    echo -e "\nIf you still have issues, check the browser console for errors (F12)"
    echo -e "and review the logs: ${GREEN}tail -f ui-debug.log${NC}"
fi 