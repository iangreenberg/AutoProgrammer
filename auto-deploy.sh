#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== AutoProgrammer Automated Deployment Tool =====${NC}"
echo -e "This script will help you deploy your AutoProgrammer to Render and Netlify for free"

# Check for required CLI tools
check_command() {
  if ! command -v $1 &> /dev/null; then
    echo -e "${RED}Error: $1 is required but not installed.${NC}"
    echo -e "Please install it with: $2"
    exit 1
  fi
}

# Check for required commands
check_command "curl" "brew install curl"
check_command "jq" "brew install jq"
check_command "git" "brew install git"

# Ask for DeepSeek API Key
echo
echo -e "${YELLOW}DeepSeek API Key Configuration${NC}"
echo -e "Your API key will be securely stored as an environment variable in Render"
read -p "Enter your DeepSeek API key: " DEEPSEEK_API_KEY

# Check if we're in the repo directory
if [ ! -d "./autoprogrammer-api" ] || [ ! -d "./autoprogrammer-ai-service" ] || [ ! -d "./autoprogrammer-ui" ]; then
  echo -e "${RED}Error: This script must be run from the root of your AutoProgrammer repository${NC}"
  echo -e "Make sure you have the following directories:"
  echo -e "  - autoprogrammer-api"
  echo -e "  - autoprogrammer-ai-service"
  echo -e "  - autoprogrammer-ui"
  exit 1
fi

# Ensure the code is ready for deployment
echo
echo -e "${YELLOW}Preparing your code for deployment...${NC}"

# Check if we have git
if [ -d ".git" ]; then
  echo "Git repository found."
  
  # Check if there are uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}You have uncommitted changes.${NC}"
    read -p "Would you like to commit these changes before deploying? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      read -p "Enter a commit message: " COMMIT_MSG
      git add .
      git commit -m "$COMMIT_MSG"
      echo -e "${GREEN}Changes committed.${NC}"
    fi
  fi
else
  echo -e "${YELLOW}Not a git repository. You'll need to manually push to GitHub.${NC}"
  read -p "Press Enter to continue or Ctrl+C to exit and set up git..."
fi

# Ensure CORS is properly configured in the API Gateway
echo
echo -e "${YELLOW}Checking CORS configuration in API Gateway...${NC}"

API_SERVER_FILE="./autoprogrammer-api/server.js"
if [ -f "$API_SERVER_FILE" ]; then
  if ! grep -q "cors" "$API_SERVER_FILE"; then
    echo -e "${RED}Warning: CORS might not be configured in your API Gateway.${NC}"
    echo -e "Make sure you have the following code in your server.js:"
    echo -e "${YELLOW}const cors = require('cors');${NC}"
    echo -e "${YELLOW}app.use(cors({${NC}"
    echo -e "${YELLOW}  origin: process.env.FRONTEND_URLS.split(','),${NC}"
    echo -e "${YELLOW}  credentials: true${NC}"
    echo -e "${YELLOW}}));${NC}"
    read -p "Press Enter to continue or Ctrl+C to exit and fix this manually..."
  else
    echo -e "${GREEN}CORS configuration found. Good!${NC}"
  fi
else
  echo -e "${RED}Error: API Gateway server.js not found at $API_SERVER_FILE${NC}"
  exit 1
fi

# Create netlify.toml for better configuration
echo
echo -e "${YELLOW}Creating Netlify configuration file...${NC}"

cat > ./autoprogrammer-ui/netlify.toml << EOL
[build]
  base = "/"
  publish = "dist"
  command = "npm install && npm run build"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOL

echo -e "${GREEN}Created netlify.toml file in autoprogrammer-ui directory${NC}"

# Create render.yaml to facilitate easy deployment
echo
echo -e "${YELLOW}Creating Render configuration file...${NC}"

cat > ./render.yaml << EOL
services:
  - type: web
    name: autoprogrammer-api
    env: node
    rootDir: autoprogrammer-api
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: RATE_LIMIT_MAX_REQUESTS
        value: 60
      - key: RATE_LIMIT_WINDOW_MS
        value: 60000
      - key: FRONTEND_URLS
        sync: false
      - key: AI_SERVICE_URL
        sync: false

  - type: web
    name: autoprogrammer-ai
    env: node
    rootDir: autoprogrammer-ai-service
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: DEEPSEEK_API_KEY
        sync: false
      - key: DEEPSEEK_API_URL
        value: https://api.deepseek.com/v1/chat/completions
      - key: DEEPSEEK_MODEL
        value: deepseek-coder-plus
      - key: DEEPSEEK_MAX_TOKENS
        value: 4096
      - key: DEEPSEEK_TEMPERATURE
        value: 0.2
      - key: RATE_LIMIT_MAX_REQUESTS
        value: 30
      - key: RATE_LIMIT_WINDOW_MS
        value: 60000
      - key: GATEWAY_URL
        sync: false
EOL

echo -e "${GREEN}Created render.yaml file to streamline deployment${NC}"

# Create deployment instructions
echo
echo -e "${GREEN}===== AutoProgrammer Deployment Ready! =====${NC}"
echo -e "Follow these final steps to complete your deployment:"
echo
echo -e "${YELLOW}1. Push your repository to GitHub:${NC}"
echo -e "   git push origin main"
echo
echo -e "${YELLOW}2. Deploy Backend Services to Render:${NC}"
echo -e "   a. Go to https://dashboard.render.com/blueprints"
echo -e "   b. Click 'New Blueprint Instance'"
echo -e "   c. Connect your GitHub repo"
echo -e "   d. Render will detect the render.yaml file and set up both services"
echo -e "   e. Add these environment variables manually during setup:"
echo -e "      - DEEPSEEK_API_KEY: $DEEPSEEK_API_KEY"
echo -e "      - The URL variables will be added after services are deployed"
echo
echo -e "${YELLOW}3. Deploy Frontend to Netlify:${NC}"
echo -e "   a. Go to https://app.netlify.com/start"
echo -e "   b. Connect to your GitHub repo"
echo -e "   c. Set the base directory to: autoprogrammer-ui"
echo -e "   d. Netlify will detect the netlify.toml file for other settings"
echo
echo -e "${YELLOW}4. Link Services:${NC}"
echo -e "   a. After all deployments complete, copy the URLs from Render dashboard"
echo -e "   b. Update environment variables:"
echo -e "      - Set AI_SERVICE_URL in API Gateway service"
echo -e "      - Set GATEWAY_URL in AI service"
echo -e "      - Add VITE_API_URL in Netlify (Environment variables section)"
echo -e "      - Set FRONTEND_URLS in API Gateway to your Netlify URL"
echo
echo -e "${YELLOW}5. Prevent Free Tier Spin-downs:${NC}"
echo -e "   a. Go to https://uptimerobot.com/ and create a free account"
echo -e "   b. Add HTTP monitors for both your Render services"
echo -e "   c. Set them to ping every 5 minutes to prevent spin-downs"
echo
echo -e "${GREEN}Your AutoProgrammer will be available online once these steps are completed!${NC}" 