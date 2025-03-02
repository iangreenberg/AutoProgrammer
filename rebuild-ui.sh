#!/bin/bash

echo "==============================================="
echo "     AutoProgrammer UI Complete Rebuild"
echo "==============================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping any existing processes...${NC}"

# Kill all node processes
pkill -f "node.*vite" || true
pkill -f "node.*gateway.js" || true  
pkill -f "node.*server.js" || true
sleep 2

# Force kill any processes on the ports
echo -e "${YELLOW}Freeing ports...${NC}"
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
lsof -ti:5174 | xargs kill -9 2>/dev/null || true
lsof -ti:4000 | xargs kill -9 2>/dev/null || true
lsof -ti:5000 | xargs kill -9 2>/dev/null || true
sleep 1

# Navigate to UI directory
cd "$(dirname "$0")/autoprogrammer-ui" || {
    echo -e "${RED}Error: UI directory not found${NC}"
    exit 1
}

# Update index.html to ensure it has the correct root element
echo -e "${YELLOW}Updating index.html...${NC}"
cat > "index.html" << 'EOL'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AutoProgrammer</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOL
echo -e "${GREEN}index.html updated${NC}"

# Clean caches
echo -e "${YELLOW}Cleaning caches...${NC}"
rm -rf node_modules/.vite
rm -rf node_modules/.cache
echo -e "${GREEN}Cache cleaned${NC}"

# Create .env file with the correct API URL
echo -e "${YELLOW}Creating .env file...${NC}"
cat > ".env" << 'EOL'
VITE_API_GATEWAY_URL=http://localhost:4000
EOL
echo -e "${GREEN}.env file created${NC}"

# Update vite.config.js to ensure it uses port 5173
echo -e "${YELLOW}Updating vite.config.js...${NC}"
cat > "vite.config.js" << 'EOL'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
    cors: true
  }
})
EOL
echo -e "${GREEN}vite.config.js updated${NC}"

# Start services in the correct order
echo -e "${YELLOW}Starting AI Service...${NC}"
cd ../autoprogrammer-ai-service || {
    echo -e "${RED}Error: AI Service directory not found${NC}"
    exit 1
}
NODE_ENV=development npm run dev > ../ai-service.log 2>&1 &
AI_PID=$!
echo -e "${GREEN}AI Service started with PID $AI_PID${NC}"
sleep 2

echo -e "${YELLOW}Starting API Gateway...${NC}"
cd ../autoprogrammer-api || {
    echo -e "${RED}Error: API Gateway directory not found${NC}"
    exit 1
}
NODE_ENV=development npm run dev > ../api-gateway.log 2>&1 &
API_PID=$!
echo -e "${GREEN}API Gateway started with PID $API_PID${NC}"
sleep 2

echo -e "${YELLOW}Starting UI...${NC}"
cd ../autoprogrammer-ui || {
    echo -e "${RED}Error: UI directory not found${NC}"
    exit 1
}
npm run dev > ../ui-rebuild.log 2>&1 &
UI_PID=$!
echo -e "${GREEN}UI started with PID $UI_PID${NC}"
sleep 3

# Check UI status
echo -e "${YELLOW}Checking UI status...${NC}"
if grep -q "Local:   http://localhost:5173" ../ui-rebuild.log; then
    echo -e "${GREEN}UI is running on port 5173 as expected!${NC}"
    UI_PORT=5173
elif grep -q "Local:   http://localhost:" ../ui-rebuild.log; then
    UI_PORT=$(grep "Local:   http://localhost:" ../ui-rebuild.log | sed 's/.*http:\/\/localhost:\([0-9]*\).*/\1/')
    echo -e "${YELLOW}UI is running on port $UI_PORT (not 5173)${NC}"
else
    echo -e "${RED}UI may not have started correctly.${NC}"
    echo -e "Please check the log file: ${YELLOW}ui-rebuild.log${NC}"
    exit 1
fi

echo -e "\n${GREEN}All services have been rebuilt and restarted!${NC}"
echo -e "${YELLOW}Please try these steps:${NC}"
echo -e "1. Open an incognito/private window"
echo -e "2. Visit ${GREEN}http://localhost:$UI_PORT/${NC}"

echo -e "\n${YELLOW}If you still see a blank page:${NC}"
echo -e "1. Check browser console for errors (F12 > Console tab)"
echo -e "2. Check logs with: ${GREEN}tail -f ui-rebuild.log${NC}"

echo "===============================================" 