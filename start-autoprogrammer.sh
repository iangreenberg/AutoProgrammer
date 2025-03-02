#!/bin/bash

# ============================================
# AutoProgrammer Microservices Start Script
# ============================================
# This script starts all AutoProgrammer microservices in the correct order
# and ensures proper environment configuration.

# Set base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR" || exit 1

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "
${BLUE}┌─────────────────────────────────────────────────┐
│                                                 │
│        AutoProgrammer Microservices Startup     │
│                                                 │
└─────────────────────────────────────────────────┘${NC}
"

# Function to check if a port is in use
check_port() {
  local port=$1
  if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null ; then
    return 0
  else
    return 1
  fi
}

# Function to kill a process by port
kill_port() {
  local port=$1
  local process_name=$2
  if check_port "$port"; then
    echo -e "${YELLOW}Port $port is in use by $process_name. Stopping...${NC}"
    lsof -ti ":$port" | xargs kill -9 2>/dev/null || true
    sleep 1
  fi
}

# Function to wait for a service to be available
wait_for_service() {
  local url=$1
  local service_name=$2
  local max_attempts=10
  local attempt=0
  
  echo -e "${YELLOW}Waiting for $service_name to be available...${NC}"
  
  while [ $attempt -lt $max_attempts ]; do
    if curl -s "$url" > /dev/null 2>&1; then
      echo -e "${GREEN}$service_name is available!${NC}"
      return 0
    fi
    
    attempt=$((attempt + 1))
    echo -e "${YELLOW}Waiting for $service_name (attempt $attempt/$max_attempts)...${NC}"
    sleep 2
  done
  
  echo -e "${RED}$service_name failed to start within the expected time.${NC}"
  return 1
}

# Stop any existing services
echo -e "${YELLOW}Stopping any existing services...${NC}"
kill_port 5000 "AI Service"
kill_port 4000 "API Gateway"
kill_port 5173 "UI"
kill_port 5174 "UI (alternate port)"

# Verify directories exist
echo -e "${YELLOW}Verifying directories...${NC}"
for dir in "autoprogrammer-ai-service" "autoprogrammer-api" "autoprogrammer-ui"; do
  if [ ! -d "$dir" ]; then
    echo -e "${RED}Error: Directory $dir not found. Please make sure you're in the correct directory.${NC}"
    exit 1
  fi
done

# Set up environment for AI Service
echo -e "${YELLOW}Setting up AI Service environment...${NC}"
cd "$BASE_DIR/autoprogrammer-ai-service" || exit 1

# Create or update .env file
cat > .env << EOF
NODE_ENV=development
PORT=5000
API_GATEWAY_URL=http://localhost:4000
DEEPSEEK_API_KEY=your-api-key-here
DEEPSEEK_MODEL=deepseek-coder
EOF

echo -e "${GREEN}AI Service environment configured.${NC}"

# Set up environment for API Gateway
echo -e "${YELLOW}Setting up API Gateway environment...${NC}"
cd "$BASE_DIR/autoprogrammer-api" || exit 1

# Create or update .env file
cat > .env << EOF
NODE_ENV=development
PORT=4000
AI_SERVICE_URL=http://localhost:5000
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:5174,http://127.0.0.1:5173,http://127.0.0.1:5174
SKIP_API_VALIDATION=true
EOF

echo -e "${GREEN}API Gateway environment configured.${NC}"

# Set up environment for UI
echo -e "${YELLOW}Setting up UI environment...${NC}"
cd "$BASE_DIR/autoprogrammer-ui" || exit 1

# Create or update .env file
cat > .env << EOF
VITE_API_GATEWAY_URL=http://localhost:4000
VITE_NODE_ENV=development
EOF

echo -e "${GREEN}UI environment configured.${NC}"

# Start AI Service
echo -e "${YELLOW}Starting AI Service...${NC}"
cd "$BASE_DIR/autoprogrammer-ai-service" || exit 1
NODE_ENV=development npm run dev > "$BASE_DIR/ai-service.log" 2>&1 &
AI_SERVICE_PID=$!
echo -e "${GREEN}AI Service started with PID $AI_SERVICE_PID${NC}"

# Wait for AI Service to be available
wait_for_service "http://localhost:5000/health" "AI Service" || {
  echo -e "${RED}Failed to start AI Service. Check logs at $BASE_DIR/ai-service.log${NC}"
  exit 1
}

# Start API Gateway
echo -e "${YELLOW}Starting API Gateway...${NC}"
cd "$BASE_DIR/autoprogrammer-api" || exit 1
NODE_ENV=development npm run dev > "$BASE_DIR/api-gateway.log" 2>&1 &
API_GATEWAY_PID=$!
echo -e "${GREEN}API Gateway started with PID $API_GATEWAY_PID${NC}"

# Wait for API Gateway to be available
wait_for_service "http://localhost:4000/health" "API Gateway" || {
  echo -e "${RED}Failed to start API Gateway. Check logs at $BASE_DIR/api-gateway.log${NC}"
  kill -9 "$AI_SERVICE_PID" 2>/dev/null || true
  exit 1
}

# Start UI
echo -e "${YELLOW}Starting UI...${NC}"
cd "$BASE_DIR/autoprogrammer-ui" || exit 1
npm run dev > "$BASE_DIR/ui.log" 2>&1 &
UI_PID=$!
echo -e "${GREEN}UI started with PID $UI_PID${NC}"

# Create stop script
echo -e "${YELLOW}Creating stop script...${NC}"
cat > "$BASE_DIR/stop-autoprogrammer.sh" << 'EOF'
#!/bin/bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping AutoProgrammer services...${NC}"

# Stop processes by port number
for port in 5000 4000 5173 5174; do
  if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}Stopping process on port $port...${NC}"
    lsof -ti ":$port" | xargs kill -9 2>/dev/null || true
  fi
done

echo -e "${GREEN}All services stopped.${NC}"
EOF

chmod +x "$BASE_DIR/stop-autoprogrammer.sh"

# Summary
echo -e "
${GREEN}┌─────────────────────────────────────────────────┐
│                                                 │
│        AutoProgrammer Services Running          │
│                                                 │
│  AI Service:  http://localhost:5000             │
│  API Gateway: http://localhost:4000             │
│  UI:          http://localhost:5173             │
│                                                 │
│  Logs:                                          │
│    - AI Service:  $BASE_DIR/ai-service.log      │
│    - API Gateway: $BASE_DIR/api-gateway.log     │
│    - UI:          $BASE_DIR/ui.log              │
│                                                 │
│  To stop all services: ./stop-autoprogrammer.sh │
│                                                 │
└─────────────────────────────────────────────────┘${NC}
"

echo -e "${BLUE}All services started successfully. You can access the UI at http://localhost:5173${NC}" 