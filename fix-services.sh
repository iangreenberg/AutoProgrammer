#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│     AutoProgrammer Services Troubleshooter      │${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────┘${NC}"
echo

# Step 1: Kill any running processes on ports 4000 and 5000
echo -e "${CYAN}Step 1: Killing any processes running on ports 4000 and 5000...${NC}"
lsof -ti:4000,5000 | xargs kill -9 2>/dev/null
echo -e "${GREEN}✓ Ports cleared${NC}"

# Step 2: Verify Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed. Please install Node.js to continue.${NC}"
    exit 1
fi
NODE_VERSION=$(node -v)
echo -e "${GREEN}✓ Node.js is installed (${NODE_VERSION})${NC}"

# Set NODE_OPTIONS to disable warnings
export NODE_OPTIONS="--no-warnings"

# Step 3: Check if required directories exist
echo -e "${CYAN}Step 3: Verifying project structure...${NC}"
BASEDIR=$(pwd)

# Check for service directories
if [ ! -d "$BASEDIR/autoprogrammer-ai-service" ]; then
    echo -e "${RED}Error: AI service directory not found at $BASEDIR/autoprogrammer-ai-service${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AI service directory exists${NC}"

if [ ! -d "$BASEDIR/autoprogrammer-api" ]; then
    echo -e "${RED}Error: API Gateway directory not found at $BASEDIR/autoprogrammer-api${NC}"
    exit 1
fi
echo -e "${GREEN}✓ API Gateway directory exists${NC}"

if [ ! -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "${YELLOW}Warning: UI directory not found at $BASEDIR/autoprogrammer-ui${NC}"
    echo -e "${YELLOW}Will continue without UI component${NC}"
    HAS_UI=false
else
    echo -e "${GREEN}✓ UI directory exists${NC}"
    HAS_UI=true
fi

# Step 4: Verify .env files
echo -e "${CYAN}Step 4: Checking environment configuration files...${NC}"

# Check and create AI service .env
if [ ! -f "$BASEDIR/autoprogrammer-ai-service/.env" ]; then
    echo -e "${YELLOW}Creating AI Service .env file from example...${NC}"
    cp "$BASEDIR/autoprogrammer-ai-service/.env.example" "$BASEDIR/autoprogrammer-ai-service/.env"
    echo -e "${YELLOW}Please update AI Service .env file with appropriate values.${NC}"
else
    echo -e "${GREEN}✓ AI Service .env file exists${NC}"
fi

# Check and create API Gateway .env
if [ ! -f "$BASEDIR/autoprogrammer-api/.env" ]; then
    echo -e "${YELLOW}Creating API Gateway .env file from example...${NC}"
    cp "$BASEDIR/autoprogrammer-api/.env.example" "$BASEDIR/autoprogrammer-api/.env"
    echo -e "${YELLOW}Please update API Gateway .env file with appropriate values.${NC}"
else
    echo -e "${GREEN}✓ API Gateway .env file exists${NC}"
fi

# Step 5: Install dependencies
echo -e "${CYAN}Step 5: Installing dependencies for all services...${NC}"

echo -e "${CYAN}Installing AI Service dependencies...${NC}"
cd "$BASEDIR/autoprogrammer-ai-service" && npm install

echo -e "${CYAN}Installing API Gateway dependencies...${NC}"
cd "$BASEDIR/autoprogrammer-api" && npm install

if [ "$HAS_UI" = true ]; then
    echo -e "${CYAN}Installing UI dependencies...${NC}"
    cd "$BASEDIR/autoprogrammer-ui" && npm install
fi

# Step 6: Start services
echo -e "${CYAN}Step 6: Starting services...${NC}"

echo -e "${CYAN}Starting AI Processing Service...${NC}"
cd "$BASEDIR/autoprogrammer-ai-service" && NODE_ENV=development nohup npm run dev > "$BASEDIR/ai-service.log" 2>&1 &
AI_SERVICE_PID=$!
sleep 3

# Check if AI service started
if ! lsof -ti:5000 > /dev/null; then
    echo -e "${RED}Error: Failed to start AI Processing Service.${NC}"
    echo -e "${YELLOW}Check logs at: $BASEDIR/ai-service.log${NC}"
    cat "$BASEDIR/ai-service.log"
    exit 1
fi
echo -e "${GREEN}✓ AI Processing Service started successfully on port 5000 (PID: $AI_SERVICE_PID)${NC}"

echo -e "${CYAN}Starting API Gateway...${NC}"
cd "$BASEDIR/autoprogrammer-api" && NODE_ENV=development nohup npm run dev > "$BASEDIR/api-gateway.log" 2>&1 &
API_GATEWAY_PID=$!
sleep 3

# Check if API Gateway started
if ! lsof -ti:4000 > /dev/null; then
    echo -e "${RED}Error: Failed to start API Gateway.${NC}"
    echo -e "${YELLOW}Check logs at: $BASEDIR/api-gateway.log${NC}"
    cat "$BASEDIR/api-gateway.log"
    exit 1
fi
echo -e "${GREEN}✓ API Gateway started successfully on port 4000 (PID: $API_GATEWAY_PID)${NC}"

# Start UI if available
if [ "$HAS_UI" = true ]; then
    echo -e "${CYAN}Starting UI service...${NC}"
    cd "$BASEDIR/autoprogrammer-ui" && nohup npm run dev > "$BASEDIR/ui.log" 2>&1 &
    UI_PID=$!
    sleep 3
    
    if pgrep -f "vite" > /dev/null; then
        echo -e "${GREEN}✓ UI service started successfully (PID: $UI_PID)${NC}"
        UI_PORT=$(grep -o "Local:   http://localhost:[0-9]*" "$BASEDIR/ui.log" | grep -o "[0-9]*$")
        echo -e "${GREEN}  UI is available at http://localhost:$UI_PORT${NC}"
    else
        echo -e "${RED}Error: Failed to start UI service.${NC}"
        echo -e "${YELLOW}Check logs at: $BASEDIR/ui.log${NC}"
        cat "$BASEDIR/ui.log"
    fi
fi

# Step 7: Verify services are running correctly
echo -e "${CYAN}Step 7: Verifying services...${NC}"

# Check AI service health
echo -e "${CYAN}Checking AI Service health...${NC}"
AI_HEALTH=$(curl -s http://localhost:5000/health || echo "Failed to connect")
if [[ "$AI_HEALTH" == *"healthy"* ]]; then
    echo -e "${GREEN}✓ AI Service is healthy${NC}"
else
    echo -e "${RED}✗ AI Service health check failed${NC}"
    echo "$AI_HEALTH"
fi

# Check API Gateway health
echo -e "${CYAN}Checking API Gateway health...${NC}"
API_HEALTH=$(curl -s http://localhost:4000/health || echo "Failed to connect")
if [[ "$API_HEALTH" == *"healthy"* ]]; then
    echo -e "${GREEN}✓ API Gateway is healthy${NC}"
else
    echo -e "${RED}✗ API Gateway health check failed${NC}"
    echo "$API_HEALTH"
fi

# Final status message
echo
echo -e "${GREEN}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│    AutoProgrammer Services Status                │${NC}"
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│  AI Service:  http://localhost:5000             │${NC}"
echo -e "${GREEN}│  API Gateway: http://localhost:4000             │${NC}"
if [ "$HAS_UI" = true ] && [ -n "$UI_PORT" ]; then
    echo -e "${GREEN}│  UI:         http://localhost:$UI_PORT             │${NC}"
fi
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│  Log files:                                     │${NC}"
echo -e "${GREEN}│  - AI Service:  $BASEDIR/ai-service.log         │${NC}"
echo -e "${GREEN}│  - API Gateway: $BASEDIR/api-gateway.log        │${NC}"
if [ "$HAS_UI" = true ]; then
    echo -e "${GREEN}│  - UI:         $BASEDIR/ui.log                │${NC}"
fi
echo -e "${GREEN}│                                                 │${NC}"
echo -e "${GREEN}│  To stop services: pkill -f 'node.*server\|gateway\|vite'  │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────┘${NC}"

# Create a file that can be sourced to stop all services
cat > stop-services.sh << EOL
#!/bin/bash
echo "Stopping AutoProgrammer services..."
pkill -f 'node.*server\|gateway\|vite'
echo "All services stopped."
EOL
chmod +x stop-services.sh

echo -e "${YELLOW}A stop-services.sh script has been created.${NC}"
echo -e "${YELLOW}Run './stop-services.sh' to stop all services.${NC}" 