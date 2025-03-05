#!/bin/bash
# Master script to set up AutoProgrammer Desktop (macOS app)
set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
printf "${BLUE}=====================================${NC}\n"
printf "${BLUE}  AutoProgrammer Desktop Setup      ${NC}\n"
printf "${BLUE}=====================================${NC}\n\n"

# Ensure we're in the AutoProgrammer directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

printf "${YELLOW}Setting up in directory: ${BASE_DIR}${NC}\n\n"

# Step 1: Run the Electron setup script
printf "${GREEN}Step 1: Setting up Electron project...${NC}\n"
./setup-electron.sh

# Step 2: Create main.js and preload.js
printf "${GREEN}Step 2: Creating main.js and preload.js...${NC}\n"
./create-main-js.sh

# Step 3: Update package.json
printf "${GREEN}Step 3: Updating package.json...${NC}\n"
./update-package-json.sh

# Step 4: Create build script
printf "${GREEN}Step 4: Creating build script...${NC}\n"
./create-build-script.sh

# Step 5: Create README.md
printf "${GREEN}Step 5: Creating README.md...${NC}\n"
cat > autoprogrammer-desktop/README.md << 'EOL'
# AutoProgrammer Desktop

A desktop application for AutoProgrammer, built with Electron.

## Prerequisites

- Node.js and npm installed
- macOS for building the application

## Development

1. Install dependencies:
```bash
npm install
```

2. Start the application in development mode:
```bash
npm start
```

## Building

To build the macOS application:

```bash
./build-macos-app.sh
```

This will:
1. Build the React UI
2. Package the Electron app
3. Create a DMG installer

The built application will be available in the `dist` directory.

## Notes

- This application uses the DeepSeek API with key: `sk-4556dc93bbe54e9b8ea29d0e655eb641`
- All services run locally within the Electron app
EOL

# Step 6: Create .gitignore
printf "${GREEN}Step 6: Creating .gitignore...${NC}\n"
cat > autoprogrammer-desktop/.gitignore << 'EOL'
# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
package-lock.json
yarn.lock

# Electron
dist/
out/

# Logs
logs/
*.log

# Mac OS
.DS_Store

# IDE files
.idea/
.vscode/
*.swp
*.swo
EOL

printf "${BLUE}=====================================${NC}\n"
printf "${GREEN}Setup complete! You can now:${NC}\n"
printf "${YELLOW}1. cd autoprogrammer-desktop${NC}\n"
printf "${YELLOW}2. Test your app with: npm start${NC}\n"
printf "${YELLOW}3. Build your app with: ./build-macos-app.sh${NC}\n"
printf "${BLUE}=====================================${NC}\n" 