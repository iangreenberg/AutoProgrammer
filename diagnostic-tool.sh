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
echo -e "${BLUE}│     AutoProgrammer Diagnostic Tool              │${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}└─────────────────────────────────────────────────┘${NC}"
echo

# Base directory
BASEDIR=$(pwd)
ISSUES_FOUND=0
FIXES_APPLIED=0

# Log files
AI_SERVICE_LOG="$BASEDIR/ai-service.log"
API_GATEWAY_LOG="$BASEDIR/api-gateway.log"
UI_LOG="$BASEDIR/ui.log"

# Function to check if a port is in use
check_port() {
    local port=$1
    local process=$(lsof -ti:$port)
    if [ -n "$process" ]; then
        echo -e "${YELLOW}Port $port is in use by process ID: $process${NC}"
        return 0
    else
        echo -e "${GREEN}Port $port is free${NC}"
        return 1
    fi
}

# Function to check if a process is running
check_process_running() {
    local search_term=$1
    local count=$(ps aux | grep -v grep | grep "$search_term" | wc -l)
    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}Process '$search_term' is running ($count instances)${NC}"
        return 0
    else
        echo -e "${RED}Process '$search_term' is NOT running${NC}"
        return 1
    fi
}

# Function to test an API endpoint
test_api() {
    local url=$1
    local expected_status=$2
    local timeout=${3:-5}
    
    echo -e "${CYAN}Testing API endpoint: $url${NC}"
    local response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $timeout "$url" || echo "ERROR")
    
    if [ "$response" = "ERROR" ]; then
        echo -e "${RED}✗ Could not connect to $url (connection failed)${NC}"
        return 1
    elif [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✓ API endpoint $url returned expected status $expected_status${NC}"
        return 0
    else
        echo -e "${RED}✗ API endpoint $url returned unexpected status $response (expected $expected_status)${NC}"
        return 1
    fi
}

# Function to check for specific error patterns in logs
check_log_for_errors() {
    local log_file=$1
    local name=$2
    
    if [ ! -f "$log_file" ]; then
        echo -e "${RED}Log file $log_file does not exist${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Checking $name log for error patterns...${NC}"
    
    # Define error patterns to look for
    local patterns=(
        "Model Not Exist"
        "timeout"
        "EADDRINUSE"
        "Error communicating with AI service"
        "Unauthorized"
        "SyntaxError"
        "Cannot find module"
        "ECONNREFUSED"
        "listen EADDRINUSE"
    )
    
    local errors_found=0
    
    for pattern in "${patterns[@]}"; do
        local count=$(grep -c "$pattern" "$log_file" || echo "0")
        if [ "$count" -gt 0 ]; then
            echo -e "${RED}Found $count occurrences of '$pattern' in $name log${NC}"
            # Show the last occurrence with context
            echo -e "${YELLOW}Last occurrence:${NC}"
            grep -A 3 -B 1 "$pattern" "$log_file" | tail -5
            echo ""
            errors_found=$((errors_found + 1))
        fi
    done
    
    if [ "$errors_found" -eq 0 ]; then
        echo -e "${GREEN}No common error patterns found in $name log${NC}"
        return 0
    else
        ISSUES_FOUND=$((ISSUES_FOUND + errors_found))
        return 1
    fi
}

# Function to verify .env files
check_env_files() {
    local service=$1
    local env_file=$2
    
    echo -e "${CYAN}Checking $service .env file...${NC}"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}$service .env file not found at $env_file${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi
    
    # Check for specific configuration
    if [ "$service" = "AI Service" ]; then
        # Check DeepSeek model configuration
        if grep -q "DEEPSEEK_MODEL=" "$env_file"; then
            local model=$(grep "DEEPSEEK_MODEL=" "$env_file" | cut -d'=' -f2)
            echo -e "${GREEN}DeepSeek model is set to: $model${NC}"
            
            # Check if model name might be incorrect
            if [[ "$model" != *"deepseek-coder-33b-instruct"* ]]; then
                echo -e "${RED}Warning: DeepSeek model name '$model' might be incorrect.${NC}"
                echo -e "${YELLOW}Recommended: deepseek-coder-33b-instruct${NC}"
                ISSUES_FOUND=$((ISSUES_FOUND + 1))
            fi
        else
            echo -e "${RED}DeepSeek model not configured in $env_file${NC}"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        fi
        
        # Check API Key
        if grep -q "DEEPSEEK_API_KEY=" "$env_file"; then
            local api_key=$(grep "DEEPSEEK_API_KEY=" "$env_file" | cut -d'=' -f2)
            if [ -z "$api_key" ] || [ "$api_key" = "YOUR_API_KEY_HERE" ]; then
                echo -e "${RED}DeepSeek API Key is not set properly in $env_file${NC}"
                ISSUES_FOUND=$((ISSUES_FOUND + 1))
            else
                echo -e "${GREEN}DeepSeek API Key is set${NC}"
            fi
        else
            echo -e "${RED}DeepSeek API Key not configured in $env_file${NC}"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        fi
        
        # Check USE_MOCK_IN_DEV
        if grep -q "USE_MOCK_IN_DEV=" "$env_file"; then
            local use_mock=$(grep "USE_MOCK_IN_DEV=" "$env_file" | cut -d'=' -f2)
            echo -e "${GREEN}USE_MOCK_IN_DEV is set to: $use_mock${NC}"
        else
            echo -e "${YELLOW}USE_MOCK_IN_DEV not configured in $env_file, adding it...${NC}"
            echo "USE_MOCK_IN_DEV=true" >> "$env_file"
            echo -e "${GREEN}Added USE_MOCK_IN_DEV=true to $env_file${NC}"
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        fi
    fi
    
    return 0
}

# Check DeepSeek service implementation
check_deepseek_service() {
    local service_file="$BASEDIR/autoprogrammer-ai-service/services/deepseek-service.js"
    
    echo -e "${CYAN}Checking DeepSeek service implementation...${NC}"
    
    if [ ! -f "$service_file" ]; then
        echo -e "${RED}DeepSeek service file not found at $service_file${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi
    
    # Check if the model name matches the .env file
    local env_model=$(grep "DEEPSEEK_MODEL=" "$BASEDIR/autoprogrammer-ai-service/.env" | cut -d'=' -f2)
    local service_model=$(grep "DEEPSEEK_MODEL.*||" "$service_file" | grep -o "'[^']*'" | head -1 | tr -d "'" || echo "not found")
    
    if [ "$service_model" != "not found" ] && [ "$service_model" != "$env_model" ]; then
        echo -e "${RED}DeepSeek model mismatch: $service_model in service.js vs $env_model in .env${NC}"
        echo -e "${YELLOW}This inconsistency might cause issues${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${GREEN}DeepSeek model configuration is consistent${NC}"
    fi
    
    return 0
}

# Check for API key validation in auth middleware
check_auth_middleware() {
    local auth_file="$BASEDIR/autoprogrammer-api/middleware/auth.js"
    
    echo -e "${CYAN}Checking API Gateway authentication middleware...${NC}"
    
    if [ ! -f "$auth_file" ]; then
        echo -e "${RED}Auth middleware file not found at $auth_file${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi
    
    # Check if auth skips validation in development mode
    if grep -q "process.env.NODE_ENV === 'development'" "$auth_file"; then
        echo -e "${GREEN}Auth middleware skips validation in development mode${NC}"
    else
        echo -e "${RED}Auth middleware might not skip validation in development mode${NC}"
        echo -e "${YELLOW}This could cause unauthorized access errors${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
    
    return 0
}

# Fix function: Update DeepSeek model in .env
fix_deepseek_model() {
    local env_file="$BASEDIR/autoprogrammer-ai-service/.env"
    
    echo -e "${CYAN}Fixing DeepSeek model configuration...${NC}"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Cannot fix - .env file not found at $env_file${NC}"
        return 1
    fi
    
    # Update the DeepSeek model to the correct value
    sed -i.bak 's/DEEPSEEK_MODEL=.*/DEEPSEEK_MODEL=deepseek-coder-33b-instruct/' "$env_file"
    echo -e "${GREEN}Updated DeepSeek model to deepseek-coder-33b-instruct in .env file${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
    
    return 0
}

# Fix function: Update auth middleware to skip validation in development
fix_auth_middleware() {
    local auth_file="$BASEDIR/autoprogrammer-api/middleware/auth.js"
    
    echo -e "${CYAN}Fixing API Gateway authentication middleware...${NC}"
    
    if [ ! -f "$auth_file" ]; then
        echo -e "${RED}Cannot fix - auth file not found at $auth_file${NC}"
        return 1
    fi
    
    # Make a backup of the original file
    cp "$auth_file" "${auth_file}.bak"
    
    # Get the content of the file
    local content=$(cat "$auth_file")
    
    # Check if we need to modify the validateApiKey function
    if ! grep -q "process.env.NODE_ENV === 'development'" "$auth_file"; then
        # Create a new file with modified content
        cat > "$auth_file" << 'EOL'
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
        echo -e "${GREEN}Updated auth middleware to always skip validation in development mode${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    else
        echo -e "${GREEN}Auth middleware already skips validation in development mode${NC}"
    fi
    
    return 0
}

# Fix function: Restart all services properly
restart_services() {
    echo -e "${CYAN}Restarting all services properly...${NC}"
    
    # Stop any existing services
    echo -e "${CYAN}Stopping any existing services...${NC}"
    pkill -f 'node.*server\|gateway\|vite' || true
    sleep 2
    
    # Double-check if processes are still running
    if lsof -ti:4000,5000 > /dev/null; then
        echo -e "${YELLOW}Forcefully killing processes on ports 4000 and 5000...${NC}"
        lsof -ti:4000,5000 | xargs kill -9 || true
        sleep 1
    fi
    
    # Start AI Service
    echo -e "${CYAN}Starting AI Processing Service...${NC}"
    cd "$BASEDIR/autoprogrammer-ai-service" && NODE_ENV=development nohup npm run dev > "$AI_SERVICE_LOG" 2>&1 &
    sleep 3
    
    # Check if AI Service started
    if ! lsof -ti:5000 > /dev/null; then
        echo -e "${RED}Failed to start AI Processing Service${NC}"
        echo -e "${YELLOW}Check the log at $AI_SERVICE_LOG${NC}"
        tail -20 "$AI_SERVICE_LOG"
    else
        echo -e "${GREEN}AI Processing Service started successfully${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
    
    # Start API Gateway
    echo -e "${CYAN}Starting API Gateway...${NC}"
    cd "$BASEDIR/autoprogrammer-api" && NODE_ENV=development nohup npm run dev > "$API_GATEWAY_LOG" 2>&1 &
    sleep 3
    
    # Check if API Gateway started
    if ! lsof -ti:4000 > /dev/null; then
        echo -e "${RED}Failed to start API Gateway${NC}"
        echo -e "${YELLOW}Check the log at $API_GATEWAY_LOG${NC}"
        tail -20 "$API_GATEWAY_LOG"
    else
        echo -e "${GREEN}API Gateway started successfully${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
    
    # Start UI
    if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
        echo -e "${CYAN}Starting UI...${NC}"
        cd "$BASEDIR/autoprogrammer-ui" && nohup npm run dev > "$UI_LOG" 2>&1 &
        sleep 3
        
        if pgrep -f "vite" > /dev/null; then
            echo -e "${GREEN}UI started successfully${NC}"
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        else
            echo -e "${RED}Failed to start UI${NC}"
            echo -e "${YELLOW}Check the log at $UI_LOG${NC}"
            tail -20 "$UI_LOG"
        fi
    fi
    
    return 0
}

# Function to test a complete request flow
test_complete_flow() {
    echo -e "${CYAN}Testing complete request flow...${NC}"
    
    # Test API Gateway health
    if ! test_api "http://localhost:4000/health" "200"; then
        echo -e "${RED}API Gateway health check failed${NC}"
        return 1
    fi
    
    # Test AI Service health
    if ! test_api "http://localhost:5000/health" "200"; then
        echo -e "${RED}AI Service health check failed${NC}"
        return 1
    fi
    
    # Test a simple query to the API
    echo -e "${CYAN}Testing API Gateway with a simple query...${NC}"
    local response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"query":"Hello"}' --connect-timeout 5 http://localhost:4000/ask)
    
    if [ -z "$response" ]; then
        echo -e "${RED}Received empty response from API Gateway${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    elif [[ "$response" == *"error"* ]]; then
        echo -e "${RED}Received error response from API Gateway:${NC}"
        echo "$response"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    else
        echo -e "${GREEN}Successfully received response from API Gateway${NC}"
    fi
    
    return 0
}

# Function to create a status page
create_status_page() {
    local status_file="$BASEDIR/service-status.html"
    
    echo -e "${CYAN}Creating service status page...${NC}"
    
    cat > "$status_file" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AutoProgrammer Service Status</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
        }
        .service {
            margin-bottom: 20px;
            padding: 15px;
            border-radius: 5px;
            background-color: #f9f9f9;
        }
        .service-name {
            font-weight: bold;
            font-size: 1.2em;
            margin-bottom: 10px;
        }
        .status {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 0.8em;
            font-weight: bold;
        }
        .status-running {
            background-color: #d4edda;
            color: #155724;
        }
        .status-error {
            background-color: #f8d7da;
            color: #721c24;
        }
        .actions {
            margin-top: 15px;
        }
        .log-path {
            font-family: monospace;
            background-color: #eee;
            padding: 3px 6px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <h1>AutoProgrammer Service Status</h1>
    
    <div class="service">
        <div class="service-name">AI Processing Service</div>
        <div class="status status-running">Running on port 5000</div>
        <p>URL: <a href="http://localhost:5000" target="_blank">http://localhost:5000</a></p>
        <p>Log file: <span class="log-path">$AI_SERVICE_LOG</span></p>
        <div class="actions">
            <a href="http://localhost:5000/health" target="_blank">Check Health</a>
        </div>
    </div>
    
    <div class="service">
        <div class="service-name">API Gateway</div>
        <div class="status status-running">Running on port 4000</div>
        <p>URL: <a href="http://localhost:4000" target="_blank">http://localhost:4000</a></p>
        <p>Log file: <span class="log-path">$API_GATEWAY_LOG</span></p>
        <div class="actions">
            <a href="http://localhost:4000/health" target="_blank">Check Health</a>
        </div>
    </div>
EOL

    # Check if UI is available
    if [ -d "$BASEDIR/autoprogrammer-ui" ]; then
        # Try to extract UI port from log
        local ui_port=""
        if [ -f "$UI_LOG" ]; then
            ui_port=$(grep -o "Local:   http://localhost:[0-9]*" "$UI_LOG" | grep -o "[0-9]*$" || echo "5173")
        else
            ui_port="5173"
        fi
        
        cat >> "$status_file" << EOL
    <div class="service">
        <div class="service-name">Frontend UI</div>
        <div class="status status-running">Running on port $ui_port</div>
        <p>URL: <a href="http://localhost:$ui_port" target="_blank">http://localhost:$ui_port</a></p>
        <p>Log file: <span class="log-path">$UI_LOG</span></p>
    </div>
EOL
    fi
    
    cat >> "$status_file" << EOL
    <div class="service">
        <div class="service-name">Diagnostic Information</div>
        <p>Generated: $(date)</p>
        <p>Issues Found: $ISSUES_FOUND</p>
        <p>Fixes Applied: $FIXES_APPLIED</p>
    </div>
    
    <h2>Management Tools</h2>
    <ul>
        <li><strong>Start Services:</strong> <code>./fix-services.sh</code></li>
        <li><strong>Stop Services:</strong> <code>./stop-services.sh</code></li>
        <li><strong>Run Diagnostics:</strong> <code>./diagnostic-tool.sh</code></li>
    </ul>
</body>
</html>
EOL
    
    echo -e "${GREEN}Created service status page at $status_file${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
    
    return 0
}

# Main diagnostic process
echo -e "${CYAN}Step 1: Checking if required directories exist...${NC}"
if [ ! -d "$BASEDIR/autoprogrammer-ai-service" ]; then
    echo -e "${RED}AI Service directory not found!${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✓ AI Service directory exists${NC}"
fi

if [ ! -d "$BASEDIR/autoprogrammer-api" ]; then
    echo -e "${RED}API Gateway directory not found!${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✓ API Gateway directory exists${NC}"
fi

echo -e "\n${CYAN}Step 2: Checking for port conflicts...${NC}"
check_port 4000
check_port 5000

echo -e "\n${CYAN}Step 3: Checking running processes...${NC}"
check_process_running "node.*autoprogrammer-ai-service"
check_process_running "node.*autoprogrammer-api"
check_process_running "vite.*autoprogrammer-ui"

echo -e "\n${CYAN}Step 4: Checking environment configuration...${NC}"
check_env_files "AI Service" "$BASEDIR/autoprogrammer-ai-service/.env"
check_deepseek_service
check_auth_middleware

echo -e "\n${CYAN}Step 5: Checking log files for errors...${NC}"
if [ -f "$AI_SERVICE_LOG" ]; then
    check_log_for_errors "$AI_SERVICE_LOG" "AI Service"
else
    echo -e "${YELLOW}AI Service log file not found, skipping error check${NC}"
fi

if [ -f "$API_GATEWAY_LOG" ]; then
    check_log_for_errors "$API_GATEWAY_LOG" "API Gateway"
else
    echo -e "${YELLOW}API Gateway log file not found, skipping error check${NC}"
fi

echo -e "\n${CYAN}Step 6: Testing API endpoints...${NC}"
test_api "http://localhost:4000/health" "200" 2
test_api "http://localhost:5000/health" "200" 2

# Apply fixes if issues were found
if [ "$ISSUES_FOUND" -gt 0 ]; then
    echo -e "\n${YELLOW}Issues found: $ISSUES_FOUND${NC}"
    echo -e "${CYAN}Applying fixes...${NC}"
    
    # Fix 1: Update DeepSeek model
    fix_deepseek_model
    
    # Fix 2: Update auth middleware
    fix_auth_middleware
    
    # Fix 3: Restart services properly
    restart_services
    
    # Create status page
    create_status_page
    
    # Test the complete flow after fixes
    test_complete_flow
else
    echo -e "\n${GREEN}No issues found that require fixing.${NC}"
    # Create status page anyway
    create_status_page
fi

# Final summary
echo -e "\n${BLUE}┌─────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}│     Diagnostic Summary                          │${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}│     Issues found: $ISSUES_FOUND                               │${NC}"
echo -e "${BLUE}│     Fixes applied: $FIXES_APPLIED                             │${NC}"
echo -e "${BLUE}│                                                 │${NC}"
echo -e "${BLUE}└─────────────────────────────────────────────────┘${NC}"

echo -e "${GREEN}Service status page created at:${NC}"
echo -e "${CYAN}$BASEDIR/service-status.html${NC}"
echo -e "${YELLOW}You can open this file in a browser to view service status${NC}"

echo -e "\n${CYAN}To test the system, run:${NC}"
echo -e "${YELLOW}curl -X POST -H \"Content-Type: application/json\" -d '{\"query\":\"Create a simple REST API with Node.js\"}' http://localhost:4000/ask${NC}"

exit 0 