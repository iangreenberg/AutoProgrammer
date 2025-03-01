#!/bin/bash

# AutoProgrammer AI Processing Service setup script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up AutoProgrammer AI Processing Service...${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js is not installed. Please install Node.js to continue.${NC}"
    exit 1
fi

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
npm install

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please update .env with your DeepSeek API key before running the service.${NC}"
fi

# Create logs directory if it doesn't exist
if [ ! -d logs ]; then
    echo -e "${GREEN}Creating logs directory...${NC}"
    mkdir -p logs
fi

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}To start the AI Processing Service in development mode:${NC}"
echo -e "  npm run dev"
echo -e ""
echo -e "${YELLOW}NOTE: For proper operation, ensure the API Gateway is running on port 4000${NC}"
echo -e "${YELLOW}and update your .env file with a valid DeepSeek API key.${NC}"

# Make the script executable
chmod +x setup.sh 