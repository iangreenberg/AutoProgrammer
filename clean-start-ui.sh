#!/bin/bash

echo "==============================================="
echo "     AutoProgrammer UI Clean Start"
echo "==============================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kill any existing UI processes
echo -e "${YELLOW}Stopping any existing UI processes...${NC}"
pkill -f "node.*vite" || true
sleep 2

# Force kill any processes on the UI ports
echo -e "${YELLOW}Freeing UI ports...${NC}"
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
lsof -ti:5174 | xargs kill -9 2>/dev/null || true
sleep 1

# Make sure the process is really gone
if lsof -i:5173 &>/dev/null; then
    echo -e "${RED}Port 5173 is still in use. Trying more aggressive cleanup...${NC}"
    lsof -i:5173 
    lsof -ti:5173 | xargs kill -9 2>/dev/null
    sleep 2
fi

# Navigate to UI directory
cd "$(dirname "$0")/autoprogrammer-ui" || {
    echo -e "${RED}Error: UI directory not found${NC}"
    exit 1
}

# Clean npm and Vite cache
echo -e "${YELLOW}Cleaning caches...${NC}"
rm -rf node_modules/.vite
rm -rf node_modules/.cache
echo -e "${GREEN}Cache cleaned${NC}"

# Start UI on a specific port
echo -e "${YELLOW}Starting UI on port 5173...${NC}"
PORT=5173 npm run dev > ../ui-clean.log 2>&1 &
UI_PID=$!
echo -e "${GREEN}UI started with PID $UI_PID${NC}"
sleep 3

# Verify the port
if grep -q "Local:   http://localhost:5173" ../ui-clean.log; then
    echo -e "${GREEN}UI is running on port 5173 as expected!${NC}"
    echo -e "Please open: ${GREEN}http://localhost:5173/${NC}"
elif grep -q "Local:   http://localhost:" ../ui-clean.log; then
    ACTUAL_PORT=$(grep "Local:   http://localhost:" ../ui-clean.log | sed 's/.*http:\/\/localhost:\([0-9]*\).*/\1/')
    echo -e "${YELLOW}UI is running on port $ACTUAL_PORT (not 5173)${NC}"
    echo -e "Please open: ${GREEN}http://localhost:$ACTUAL_PORT/${NC}"
else
    echo -e "${RED}UI may not have started correctly.${NC}"
    echo -e "Please check the log file: ${YELLOW}ui-clean.log${NC}"
fi

echo "===============================================" 