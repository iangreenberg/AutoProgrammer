#!/bin/bash

echo "==============================================="
echo "     AutoProgrammer UI Reset Tool"
echo "==============================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Stop all services
echo -e "${YELLOW}Stopping all services...${NC}"
pkill -f "node.*vite" || true
pkill -f "node.*gateway.js" || true  
pkill -f "node.*server.js" || true
sleep 2

# Force kill any processes on the UI ports
echo -e "${YELLOW}Freeing UI ports...${NC}"
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
lsof -ti:5174 | xargs kill -9 2>/dev/null || true
sleep 1

# Navigate to UI directory
cd "$(dirname "$0")/autoprogrammer-ui"

# Clean npm and Vite cache
echo -e "${YELLOW}Cleaning caches...${NC}"
npm cache clean --force
rm -rf node_modules/.vite
rm -rf node_modules/.cache
echo -e "${GREEN}Cache cleaned${NC}"

# Create a simple test page
echo -e "${YELLOW}Creating test page...${NC}"
mkdir -p public
cat > public/test-ui.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UI Test</title>
    <style>
        body { font-family: Arial; margin: 40px; line-height: 1.6; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
        h1 { color: #2563eb; }
        button { background: #2563eb; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }
        pre { background: #f1f1f1; padding: 10px; border-radius: 4px; overflow: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>AutoProgrammer UI Test Page</h1>
        <p>This page confirms that the Vite server is working correctly.</p>
        
        <h2>Test API Connection</h2>
        <button onclick="testAPI()">Test API Gateway</button>
        <pre id="api-result">Click the button to test...</pre>
        
        <h2>Environment Variables</h2>
        <pre id="env-vars">Loading...</pre>
        
        <h2>Troubleshooting</h2>
        <ul>
            <li>If this page loads but the React app doesn't, check the browser console for errors</li>
            <li>Try accessing the React app in an incognito/private window</li>
            <li>Check that all services are running (UI, API Gateway, AI Service)</li>
            <li>Verify that the API Gateway URL is correctly set in the UI's .env file</li>
        </ul>
        
        <p><a href="/">Go to React App</a></p>
    </div>
    
    <script>
        function testAPI() {
            const resultEl = document.getElementById('api-result');
            resultEl.textContent = 'Testing connection...';
            
            fetch('http://localhost:4000/health')
                .then(res => res.json())
                .then(data => {
                    resultEl.textContent = JSON.stringify(data, null, 2);
                })
                .catch(err => {
                    resultEl.textContent = 'Error: ' + err.message;
                });
        }
        
        // Display environment info
        document.getElementById('env-vars').textContent = 
            'Browser: ' + navigator.userAgent + '\n' +
            'URL: ' + window.location.href;
    </script>
</body>
</html>
EOF
echo -e "${GREEN}Test page created${NC}"

# Start services in the correct order
echo -e "${YELLOW}Starting AI Service...${NC}"
cd ../autoprogrammer-ai-service
NODE_ENV=development npm run dev > ../ai-service.log 2>&1 &
AI_PID=$!
echo -e "${GREEN}AI Service started with PID $AI_PID${NC}"
sleep 2

echo -e "${YELLOW}Starting API Gateway...${NC}"
cd ../autoprogrammer-api
NODE_ENV=development npm run dev > ../api-gateway.log 2>&1 &
API_PID=$!
echo -e "${GREEN}API Gateway started with PID $API_PID${NC}"
sleep 2

echo -e "${YELLOW}Starting UI...${NC}"
cd ../autoprogrammer-ui
npm run dev > ../ui.log 2>&1 &
UI_PID=$!
echo -e "${GREEN}UI started with PID $UI_PID${NC}"
sleep 3

# Check which port the UI is running on
UI_PORT=5173
if grep -q "Port 5173 is in use" ../ui.log; then
    UI_PORT=5174
    echo -e "${YELLOW}UI is running on port $UI_PORT (port 5173 was in use)${NC}"
else
    echo -e "${GREEN}UI is running on port $UI_PORT${NC}"
fi

echo -e "\n${GREEN}All services have been restarted!${NC}"
echo -e "${YELLOW}Please try these steps:${NC}"
echo -e "1. Open an incognito/private window"
echo -e "2. Visit ${GREEN}http://localhost:$UI_PORT/test-ui.html${NC} to verify static serving"
echo -e "3. Then try ${GREEN}http://localhost:$UI_PORT/${NC} for the React app"
echo -e "\n${YELLOW}If you still see a blank page:${NC}"
echo -e "1. Check browser console for errors (F12 > Console tab)"
echo -e "2. Check logs with: ${GREEN}tail -f ui.log${NC}"

echo "===============================================" 