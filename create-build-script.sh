#!/bin/bash
# Script to create build script for Electron app

# Ensure we're in the autoprogrammer-desktop directory
if [[ $(basename "$PWD") != "autoprogrammer-desktop" ]]; then
  if [[ -d "autoprogrammer-desktop" ]]; then
    cd autoprogrammer-desktop
  else
    echo "Error: autoprogrammer-desktop directory not found"
    echo "Please run setup-electron.sh first or navigate to the correct directory"
    exit 1
  fi
fi

# Create build script
cat > build-macos-app.sh << 'EOL'
#!/bin/bash

# Build script for AutoProgrammer Desktop (macOS app)
set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
printf "${BLUE}=====================================${NC}\n"
printf "${BLUE}  AutoProgrammer Desktop Builder     ${NC}\n"
printf "${BLUE}=====================================${NC}\n\n"

# Ensure we're in the AutoProgrammer directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
DESKTOP_DIR="$SCRIPT_DIR"

printf "${YELLOW}Building in directory: ${BASE_DIR}${NC}\n\n"

# Step 1: Build the React UI
printf "${GREEN}Step 1: Building React UI...${NC}\n"
cd "$BASE_DIR/autoprogrammer-ui"
npm run build

# Check if build was successful
if [ ! -d "$BASE_DIR/autoprogrammer-ui/dist" ]; then
    printf "${RED}React UI build failed. Check for errors.${NC}\n"
    exit 1
fi

# Step 2: Build the Electron app
printf "${GREEN}Step 2: Building Electron app...${NC}\n"
cd "$DESKTOP_DIR"
npm run build:mac

# Check if the build was successful
if [ ! -d "$DESKTOP_DIR/dist" ]; then
    printf "${RED}Electron build failed. Check for errors.${NC}\n"
    exit 1
fi

printf "${GREEN}Build completed successfully!${NC}\n"
printf "${YELLOW}The macOS app is available in: ${DESKTOP_DIR}/dist${NC}\n"
EOL

# Make build script executable
chmod +x build-macos-app.sh

# Create entitlements.plist for code signing
cat > entitlements.plist << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
</dict>
</plist>
EOL

echo "Build script and entitlements.plist created successfully!" 