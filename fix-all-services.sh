#!/bin/bash

echo "=========================================================="
echo "        AutoProgrammer Complete System Reset"
echo "=========================================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Stopping all existing processes...${NC}"

# Kill all relevant processes
echo -e "Killing all node processes related to AutoProgrammer..."
pkill -f "node.*vite" || true
pkill -f "node.*gateway.js" || true
pkill -f "node.*server.js" || true
sleep 2

# Force kill any processes on the ports
echo -e "Forcefully freeing all ports..."
for port in 4000 5000 5173 5174; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo -e "Killing process $pid using port $port"
        kill -9 $pid 2>/dev/null || true
    fi
done
sleep 2

# Verify ports are free
for port in 4000 5000 5173 5174; do
    if lsof -i:$port &>/dev/null; then
        echo -e "${RED}Port $port is still in use. Please check manually with 'lsof -i:$port'${NC}"
        echo -e "You may need to reboot your system if processes are stuck."
        exit 1
    else
        echo -e "${GREEN}Port $port is free${NC}"
    fi
done

echo -e "\n${YELLOW}Step 2: Cleaning environment and caches...${NC}"

# Clean up log files
echo -e "Cleaning log files..."
rm -f ui-debug.log api-debug.log ai-debug.log ui-rebuild.log ui-clean.log 2>/dev/null

# Set up the project root for reference
PROJECT_ROOT="$(pwd)"
echo -e "Project root: ${PROJECT_ROOT}"

# Check if directories exist
if [ ! -d "${PROJECT_ROOT}/autoprogrammer-ui" ]; then
    echo -e "${RED}Error: UI directory not found at ${PROJECT_ROOT}/autoprogrammer-ui${NC}"
    exit 1
fi

if [ ! -d "${PROJECT_ROOT}/autoprogrammer-api" ]; then
    echo -e "${RED}Error: API Gateway directory not found at ${PROJECT_ROOT}/autoprogrammer-api${NC}"
    exit 1
fi

if [ ! -d "${PROJECT_ROOT}/autoprogrammer-ai-service" ]; then
    echo -e "${RED}Error: AI Service directory not found at ${PROJECT_ROOT}/autoprogrammer-ai-service${NC}"
    exit 1
fi

# Fix UI configuration
echo -e "\n${YELLOW}Step 3: Configuring UI...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ui"

# Update Vite config
echo -e "Updating vite.config.js..."
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

# Update index.html
echo -e "Updating index.html..."
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

# Clean UI caches
echo -e "Cleaning UI caches..."
rm -rf node_modules/.vite node_modules/.cache

# Create .env file with the correct API URL
echo -e "Creating .env file..."
cat > ".env" << 'EOL'
VITE_API_GATEWAY_URL=http://localhost:4000
EOL
echo -e "${GREEN}UI configuration complete${NC}"

# Fix API Gateway configuration
echo -e "\n${YELLOW}Step 4: Configuring API Gateway...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-api"

# Create .env file if needed
echo -e "Creating .env file..."
cat > ".env" << 'EOL'
NODE_ENV=development
PORT=4000
AI_SERVICE_URL=http://localhost:5000
CORS_ORIGIN=http://localhost:5173,http://localhost:5174
EOL
echo -e "${GREEN}API Gateway configuration complete${NC}"

# Fix AI Service configuration
echo -e "\n${YELLOW}Step 5: Configuring AI Service...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ai-service"

# Create .env file
echo -e "Creating .env file..."
cat > ".env" << 'EOL'
NODE_ENV=development
PORT=5000
GATEWAY_URL=http://localhost:4000
DEEPSEEK_MODEL=deepseek-coder-33b-instruct
EOL
echo -e "${GREEN}AI Service configuration complete${NC}"

# Start services in the correct order
echo -e "\n${YELLOW}Step 6: Starting AI Service...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ai-service"
NODE_ENV=development npm run dev > "${PROJECT_ROOT}/ai-debug.log" 2>&1 &
AI_PID=$!
echo -e "${GREEN}AI Service started with PID $AI_PID${NC}"
sleep 3

# Check if AI Service is running
if ! ps -p $AI_PID > /dev/null; then
    echo -e "${RED}AI Service failed to start. Check logs: ${PROJECT_ROOT}/ai-debug.log${NC}"
    tail -n 20 "${PROJECT_ROOT}/ai-debug.log"
    echo -e "${YELLOW}Continuing with other services...${NC}"
else
    echo -e "${GREEN}AI Service is running${NC}"
fi

echo -e "\n${YELLOW}Step 7: Starting API Gateway...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-api"
NODE_ENV=development npm run dev > "${PROJECT_ROOT}/api-debug.log" 2>&1 &
API_PID=$!
echo -e "${GREEN}API Gateway started with PID $API_PID${NC}"
sleep 3

# Check if API Gateway is running
if ! ps -p $API_PID > /dev/null; then
    echo -e "${RED}API Gateway failed to start. Check logs: ${PROJECT_ROOT}/api-debug.log${NC}"
    tail -n 20 "${PROJECT_ROOT}/api-debug.log"
    echo -e "${YELLOW}Continuing with UI service...${NC}"
else
    echo -e "${GREEN}API Gateway is running${NC}"
fi

echo -e "\n${YELLOW}Step 8: Starting UI...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ui"
npm run dev > "${PROJECT_ROOT}/ui-debug.log" 2>&1 &
UI_PID=$!
echo -e "${GREEN}UI started with PID $UI_PID${NC}"
sleep 3

# Check UI status
echo -e "${YELLOW}Checking UI status...${NC}"
if grep -q "Local:   http://localhost:5173" "${PROJECT_ROOT}/ui-debug.log"; then
    echo -e "${GREEN}UI is running on port 5173 as expected!${NC}"
    UI_PORT=5173
elif grep -q "Local:   http://localhost:" "${PROJECT_ROOT}/ui-debug.log"; then
    UI_PORT=$(grep "Local:   http://localhost:" "${PROJECT_ROOT}/ui-debug.log" | sed 's/.*http:\/\/localhost:\([0-9]*\).*/\1/')
    echo -e "${YELLOW}UI is running on port $UI_PORT (not 5173)${NC}"
else
    echo -e "${RED}UI may not have started correctly.${NC}"
    echo -e "Please check the log file: ${PROJECT_ROOT}/ui-debug.log"
    tail -n 20 "${PROJECT_ROOT}/ui-debug.log"
    exit 1
fi

# Final verification
echo -e "\n${YELLOW}Step 9: Verifying services are running...${NC}"
echo -e "Checking AI Service (PID: $AI_PID)..."
if ps -p $AI_PID > /dev/null; then
    echo -e "${GREEN}✓ AI Service is running${NC}"
else
    echo -e "${RED}✗ AI Service is not running${NC}"
fi

echo -e "Checking API Gateway (PID: $API_PID)..."
if ps -p $API_PID > /dev/null; then
    echo -e "${GREEN}✓ API Gateway is running${NC}"
else
    echo -e "${RED}✗ API Gateway is not running${NC}"
fi

echo -e "Checking UI (PID: $UI_PID)..."
if ps -p $UI_PID > /dev/null; then
    echo -e "${GREEN}✓ UI is running on port $UI_PORT${NC}"
else
    echo -e "${RED}✗ UI is not running${NC}"
fi

# Create a test HTML page for static file serving test
echo -e "\n${YELLOW}Step 10: Creating test pages...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ui"
mkdir -p public
cat > "public/test-static.html" << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Static Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f0f2f5;
        }
        .container {
            text-align: center;
            padding: 30px;
            border-radius: 8px;
            background-color: white;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            max-width: 500px;
        }
        h1 {
            color: #4285f4;
        }
        p {
            color: #5f6368;
            margin: 20px 0;
        }
        .success {
            color: #34a853;
            font-weight: bold;
        }
        a {
            color: #4285f4;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Static File Test</h1>
        <p class="success">✓ The static file serving is working!</p>
        <p>This confirms that Vite is correctly serving static files from the public directory.</p>
        <p><a href="/">Return to the React App</a></p>
    </div>
</body>
</html>
EOL
echo -e "${GREEN}Test page created at public/test-static.html${NC}"

# Summary
echo -e "\n${BLUE}===========================================================${NC}"
echo -e "${BLUE}                 System Reset Complete                     ${NC}"
echo -e "${BLUE}===========================================================${NC}"
echo -e "\n${GREEN}All services have been configured and restarted:${NC}"
echo -e "✓ AI Service:  http://localhost:5000 (PID: $AI_PID)"
echo -e "✓ API Gateway: http://localhost:4000 (PID: $API_PID)"
echo -e "✓ UI:          http://localhost:$UI_PORT (PID: $UI_PID)"

echo -e "\n${YELLOW}Please try these steps:${NC}"
echo -e "1. Open a NEW incognito/private window in Chrome"
echo -e "2. Visit ${GREEN}http://localhost:$UI_PORT/test-static.html${NC} first to verify static serving"
echo -e "3. Then visit ${GREEN}http://localhost:$UI_PORT/${NC} for the main React app"

echo -e "\n${YELLOW}If you still see issues:${NC}"
echo -e "1. Check browser console for errors (F12 > Console tab)"
echo -e "2. Check service logs with these commands:"
echo -e "   - UI log:        ${GREEN}tail -f ui-debug.log${NC}"
echo -e "   - API Gateway:   ${GREEN}tail -f api-debug.log${NC}"
echo -e "   - AI Service:    ${GREEN}tail -f ai-debug.log${NC}"

echo -e "\n${YELLOW}To stop all services:${NC}"
echo -e "Run: ${GREEN}kill $AI_PID $API_PID $UI_PID${NC}"
echo "==========================================================" 