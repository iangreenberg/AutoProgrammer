#!/bin/bash

# Script to build the AutoProgrammer macOS app

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building AutoProgrammer Desktop App for macOS${NC}"

# Move to the directory containing this script
cd "$(dirname "$0")"

# Step 1: Build the UI
echo -e "${YELLOW}Building the React UI...${NC}"
cd ../autoprogrammer-ui
npm run build
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to build UI${NC}"
  exit 1
fi
echo -e "${GREEN}UI built successfully!${NC}"

# Step 2: Create the desktop app
echo -e "${YELLOW}Building the Electron app...${NC}"
cd ../autoprogrammer-desktop
npm run build:mac
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to build Electron app${NC}"
  exit 1
fi
echo -e "${GREEN}Desktop app built successfully!${NC}"

# Print final message
echo -e "${BLUE}AutoProgrammer Desktop App build complete!${NC}"
echo -e "${YELLOW}You can find the app in:${NC} $(pwd)/dist" 