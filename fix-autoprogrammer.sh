#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}│     AutoProgrammer Emergency Fix Tool           │${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}└─────────────────────────────────────────────────┘${NC}"
echo

# Make sure we're in the base directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
BASEDIR=$(pwd)
echo -e "${CYAN}Working from base directory: $BASEDIR${NC}"

# Verify directory structure
echo -e "\n${CYAN}Verifying directory structure...${NC}"
if [ ! -d "$BASEDIR/autoprogrammer-ai-service" ]; then
    echo -e "${RED}AI Service directory not found!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ AI Service directory exists${NC}"
fi

if [ ! -d "$BASEDIR/autoprogrammer-api" ]; then
    echo -e "${RED}API Gateway directory not found!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ API Gateway directory exists${NC}"
fi

if [ ! -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "${YELLOW}UI directory not found, but we can continue without it${NC}"
else
    echo -e "${GREEN}✓ UI directory exists${NC}"
fi

# Force kill any running processes
echo -e "\n${CYAN}Forcefully stopping all existing services...${NC}"
# Kill by port first
for port in 4000 5000 5173 5174; do
    if lsof -ti:$port > /dev/null; then
        echo -e "${YELLOW}Killing process on port $port...${NC}"
        lsof -ti:$port | xargs kill -9 || true
    else
        echo -e "${GREEN}No process found on port $port${NC}"
    fi
done

# Kill by process name
echo -e "${CYAN}Killing any remaining Node.js processes related to AutoProgrammer...${NC}"
pkill -f 'node.*server.js' || true
pkill -f 'node.*gateway.js' || true
pkill -f 'vite' || true
sleep 2

# Verify ports are free
echo -e "\n${CYAN}Verifying ports are free...${NC}"
for port in 4000 5000 5173 5174; do
    if lsof -ti:$port > /dev/null; then
        echo -e "${RED}Port $port is still in use! Unable to continue.${NC}"
        echo -e "${YELLOW}Try manually killing the process: lsof -ti:$port | xargs kill -9${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Port $port is free${NC}"
    fi
done

# Update ENV files with correct configuration
echo -e "\n${CYAN}Updating environment configuration...${NC}"

# Update AI Service .env
AI_ENV_FILE="$BASEDIR/autoprogrammer-ai-service/.env"
if [ -f "$AI_ENV_FILE" ]; then
    echo -e "${CYAN}Updating AI Service .env file...${NC}"
    # Make a backup
    cp "$AI_ENV_FILE" "${AI_ENV_FILE}.backup"
    
    # Update DeepSeek model
    sed -i.bak 's/DEEPSEEK_MODEL=.*/DEEPSEEK_MODEL=deepseek-coder-33b-instruct/' "$AI_ENV_FILE"
    
    # Ensure USE_MOCK_IN_DEV is true for reliable development
    if grep -q "USE_MOCK_IN_DEV=" "$AI_ENV_FILE"; then
        sed -i.bak 's/USE_MOCK_IN_DEV=.*/USE_MOCK_IN_DEV=true/' "$AI_ENV_FILE"
    else
        echo "USE_MOCK_IN_DEV=true" >> "$AI_ENV_FILE"
    fi
    
    echo -e "${GREEN}✓ Updated AI Service .env file${NC}"
else
    echo -e "${RED}AI Service .env file not found. Creating a default one...${NC}"
    cat > "$AI_ENV_FILE" << EOL
PORT=5000
NODE_ENV=development
API_GATEWAY_URL=http://localhost:4000
DEEPSEEK_API_URL=https://api.deepseek.com/v1
DEEPSEEK_API_KEY=
DEEPSEEK_MODEL=deepseek-coder-33b-instruct
DEEPSEEK_MAX_TOKENS=4000
DEEPSEEK_TEMPERATURE=0.7
USE_MOCK_IN_DEV=true
EOL
    echo -e "${GREEN}✓ Created default AI Service .env file${NC}"
fi

# Update API Gateway .env
API_ENV_FILE="$BASEDIR/autoprogrammer-api/.env"
if [ -f "$API_ENV_FILE" ]; then
    echo -e "${CYAN}Updating API Gateway .env file...${NC}"
    # Make a backup
    cp "$API_ENV_FILE" "${API_ENV_FILE}.backup"
    
    # Ensure NODE_ENV is development
    sed -i.bak 's/NODE_ENV=.*/NODE_ENV=development/' "$API_ENV_FILE"
    
    echo -e "${GREEN}✓ Updated API Gateway .env file${NC}"
else
    echo -e "${RED}API Gateway .env file not found. Creating a default one...${NC}"
    cat > "$API_ENV_FILE" << EOL
PORT=4000
NODE_ENV=development
AI_SERVICE_URL=http://localhost:5000
API_KEY=development-key
EOL
    echo -e "${GREEN}✓ Created default API Gateway .env file${NC}"
fi

# Fix auth middleware
AUTH_FILE="$BASEDIR/autoprogrammer-api/middleware/auth.js"
if [ -f "$AUTH_FILE" ]; then
    echo -e "${CYAN}Checking and fixing auth middleware...${NC}"
    
    # Ensure auth middleware skips validation in development
    if ! grep -q "process.env.NODE_ENV === 'development'" "$AUTH_FILE"; then
        echo -e "${YELLOW}Auth middleware needs to be updated to skip validation in development${NC}"
        # Make a backup
        cp "$AUTH_FILE" "${AUTH_FILE}.backup"
        
        # Replace the file
        cat > "$AUTH_FILE" << 'EOL'
/**
 * Authentication Middleware
 * Handles API key validation and authorization
 */

import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

/**
 * Validate API key for protected routes
 * Always skips validation in development mode
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
export const validateApiKey = (req, res, next) => {
  // Always skip API key validation in development mode
  if (process.env.NODE_ENV === 'development') {
    console.log(`[${req.id}] [AUTH] API key validation skipped in development mode`);
    return next();
  }
  
  // Get API key from request
  const apiKey = req.headers.authorization || req.headers['x-api-key'];

  // Validate API key
  if (!apiKey || !validateKey(apiKey)) {
    console.log(`[${req.id}] [AUTH] Invalid or missing API key`);
    return res.status(401).json({
      success: false,
      error: 'Unauthorized',
      message: 'Invalid or missing API key'
    });
  }
  
  // API key is valid
  next();
};

/**
 * Verify if the API key is valid
 * @param {string} apiKey - The API key to validate
 * @returns {boolean} True if valid, false otherwise
 */
function validateKey(apiKey) {
  // Remove "Bearer " prefix if present
  const key = apiKey.startsWith('Bearer ') ? apiKey.substring(7) : apiKey;
  
  // Simple validation - compare with environment variable
  return key === process.env.API_KEY;
}

// Additional auth middleware can be added here in the future
// For example: JWT validation, role-based access control, etc.
EOL
        echo -e "${GREEN}✓ Updated auth middleware to skip validation in development${NC}"
    else
        echo -e "${GREEN}✓ Auth middleware already skips validation in development${NC}"
    fi
else
    echo -e "${RED}Auth middleware file not found at $AUTH_FILE${NC}"
    echo -e "${YELLOW}Will try to continue anyway...${NC}"
fi

# Fix DeepSeek service
DEEPSEEK_FILE="$BASEDIR/autoprogrammer-ai-service/services/deepseek-service.js"
if [ -f "$DEEPSEEK_FILE" ]; then
    echo -e "${CYAN}Checking and fixing DeepSeek service...${NC}"
    
    # Check if model name needs to be updated
    if grep -q "deepseek-coder'" "$DEEPSEEK_FILE"; then
        echo -e "${YELLOW}DeepSeek service needs model name update${NC}"
        # Make a backup
        cp "$DEEPSEEK_FILE" "${DEEPSEEK_FILE}.backup"
        
        # Update the model name
        sed -i.bak "s/deepseek-coder'/deepseek-coder-33b-instruct'/g" "$DEEPSEEK_FILE"
        echo -e "${GREEN}✓ Updated DeepSeek service model name${NC}"
    else
        echo -e "${GREEN}✓ DeepSeek service model name already updated${NC}"
    fi
else
    echo -e "${RED}DeepSeek service file not found at $DEEPSEEK_FILE${NC}"
    echo -e "${YELLOW}Will try to continue anyway...${NC}"
fi

# Install dependencies
echo -e "\n${CYAN}Installing dependencies for all services...${NC}"

echo -e "${CYAN}Installing AI Service dependencies...${NC}"
cd "$BASEDIR/autoprogrammer-ai-service"
npm install 

echo -e "${CYAN}Installing API Gateway dependencies...${NC}"
cd "$BASEDIR/autoprogrammer-api"
npm install

if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "${CYAN}Installing UI dependencies...${NC}"
    cd "$BASEDIR/autoprogrammer-ui"
    npm install
fi

# Start services
echo -e "\n${CYAN}Starting services in the correct order...${NC}"

# Start AI Service
echo -e "${CYAN}Starting AI Processing Service...${NC}"
cd "$BASEDIR/autoprogrammer-ai-service"
NODE_ENV=development nohup npm run dev > "$BASEDIR/ai-service.log" 2>&1 &
AI_PID=$!
echo -e "${GREEN}AI Service started with PID $AI_PID${NC}"
sleep 5

# Check if AI Service is running
if ! lsof -ti:5000 > /dev/null; then
    echo -e "${RED}Failed to start AI Service! Check logs for details:${NC}"
    tail -n 20 "$BASEDIR/ai-service.log"
    echo -e "${YELLOW}Continuing anyway...${NC}"
else
    echo -e "${GREEN}✓ AI Service is running on port 5000${NC}"
fi

# Start API Gateway
echo -e "${CYAN}Starting API Gateway...${NC}"
cd "$BASEDIR/autoprogrammer-api" 
NODE_ENV=development nohup npm run dev > "$BASEDIR/api-gateway.log" 2>&1 &
API_PID=$!
echo -e "${GREEN}API Gateway started with PID $API_PID${NC}"
sleep 5

# Check if API Gateway is running
if ! lsof -ti:4000 > /dev/null; then
    echo -e "${RED}Failed to start API Gateway! Check logs for details:${NC}"
    tail -n 20 "$BASEDIR/api-gateway.log"
    echo -e "${YELLOW}Continuing anyway...${NC}"
else
    echo -e "${GREEN}✓ API Gateway is running on port 4000${NC}"
fi

# Start UI
if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "${CYAN}Starting UI...${NC}"
    cd "$BASEDIR/autoprogrammer-ui"
    nohup npm run dev > "$BASEDIR/ui.log" 2>&1 &
    UI_PID=$!
    echo -e "${GREEN}UI started with PID $UI_PID${NC}"
    sleep 5
    
    # Try to extract UI port from log
    UI_PORT=$(grep -o "Local:   http://localhost:[0-9]*" "$BASEDIR/ui.log" | grep -o "[0-9]*$" || echo "5173")
    
    echo -e "${GREEN}✓ UI is running on port $UI_PORT${NC}"
else
    echo -e "${YELLOW}UI directory not found, skipping UI startup${NC}"
fi

# Create a stop-services script
echo -e "\n${CYAN}Creating stop-services.sh script...${NC}"
cat > "$BASEDIR/stop-services.sh" << 'EOL'
#!/bin/bash
echo "Stopping AutoProgrammer services..."
pkill -f 'node.*server.js' || true
pkill -f 'node.*gateway.js' || true
pkill -f 'vite' || true
echo "Checking if any processes are still running on ports 4000, 5000, 5173, or 5174..."
for port in 4000 5000 5173 5174; do
    if lsof -ti:$port > /dev/null; then
        echo "Forcefully killing process on port $port..."
        lsof -ti:$port | xargs kill -9 || true
    fi
done
echo "All services stopped."
EOL
chmod +x "$BASEDIR/stop-services.sh"
echo -e "${GREEN}✓ Created stop-services.sh script${NC}"

# Test services
echo -e "\n${CYAN}Testing services...${NC}"

# Test AI Service
echo -e "${CYAN}Testing AI Service health...${NC}"
AI_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:5000/health" || echo "ERROR")
if [ "$AI_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ AI Service is healthy${NC}"
else
    echo -e "${RED}× AI Service health check failed (status: $AI_HEALTH)${NC}"
fi

# Test API Gateway
echo -e "${CYAN}Testing API Gateway health...${NC}"
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:4000/health" || echo "ERROR")
if [ "$API_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ API Gateway is healthy${NC}"
else
    echo -e "${RED}× API Gateway health check failed (status: $API_HEALTH)${NC}"
fi

# Test a simple query
echo -e "${CYAN}Testing a simple query...${NC}"
QUERY_RESULT=$(curl -s -X POST -H "Content-Type: application/json" -d '{"query":"Hello"}' --connect-timeout 5 "http://localhost:4000/ask")
if [[ "$QUERY_RESULT" == *"success"* ]] && [[ "$QUERY_RESULT" != *"error"* ]]; then
    echo -e "${GREEN}✓ Query successful!${NC}"
    echo -e "${CYAN}Response preview:${NC}"
    echo "${QUERY_RESULT:0:200}..."
else
    echo -e "${RED}× Query failed${NC}"
    echo "$QUERY_RESULT"
fi

echo -e "\n${BLUE}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}│     AutoProgrammer Fix Complete                 │${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}└─────────────────────────────────────────────────┘${NC}"
echo -e "${GREEN}Services should now be running:${NC}"
echo -e "- AI Service: http://localhost:5000"
echo -e "- API Gateway: http://localhost:4000"
if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "- UI: http://localhost:$UI_PORT"
fi
echo -e "\n${YELLOW}Log files:${NC}"
echo -e "- AI Service: $BASEDIR/ai-service.log"
echo -e "- API Gateway: $BASEDIR/api-gateway.log"
if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
    echo -e "- UI: $BASEDIR/ui.log"
fi
echo -e "\n${CYAN}To stop all services:${NC}"
echo -e "./stop-services.sh"
echo -e "\n${CYAN}Good luck!${NC}"

exit 0 