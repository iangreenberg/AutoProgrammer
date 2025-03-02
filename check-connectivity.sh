#!/bin/bash

echo "Checking AutoProgrammer connectivity..."
echo

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check UI Server
echo -e "${YELLOW}Checking UI Server (port 5173)...${NC}"
if curl -s http://localhost:5173/ > /dev/null; then
  echo -e "${GREEN}✓ UI Server is accessible${NC}"
else
  echo -e "${RED}✗ UI Server is not accessible${NC}"
  # Try alternative port
  if curl -s http://localhost:5174/ > /dev/null; then
    echo -e "${YELLOW}! UI Server is running on port 5174 instead of 5173${NC}"
    echo -e "${YELLOW}  Try accessing: http://localhost:5174${NC}"
  fi
fi

# Check API Gateway
echo -e "\n${YELLOW}Checking API Gateway (port 4000)...${NC}"
if response=$(curl -s http://localhost:4000/health); then
  echo -e "${GREEN}✓ API Gateway is accessible${NC}"
  echo -e "  Response: $response"
else
  echo -e "${RED}✗ API Gateway is not accessible${NC}"
fi

# Check AI Service
echo -e "\n${YELLOW}Checking AI Service (port 5000)...${NC}"
if response=$(curl -s http://localhost:5000/health); then
  echo -e "${GREEN}✓ AI Service is accessible${NC}"
  echo -e "  Response: $response"
else
  echo -e "${RED}✗ AI Service is not accessible${NC}"
fi

# Check cross-domain access
echo -e "\n${YELLOW}Checking cross-domain access (CORS)...${NC}"
cors_check=$(curl -s -I -X OPTIONS -H "Origin: http://localhost:5173" http://localhost:4000/health | grep -i "Access-Control-Allow-Origin")
if [[ -n "$cors_check" ]]; then
  echo -e "${GREEN}✓ CORS is properly configured${NC}"
  echo -e "  $cors_check"
else
  echo -e "${RED}✗ CORS might not be properly configured${NC}"
fi

echo -e "\n${YELLOW}Completed connectivity check${NC}" 