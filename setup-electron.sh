#!/bin/bash
# Simple setup script for Electron project

# Create directory if it doesn't exist
mkdir -p autoprogrammer-desktop
cd autoprogrammer-desktop

# Initialize npm project
npm init -y

# Install dependencies
npm install electron electron-builder --save-dev
npm install electron-is-dev --save

echo "Electron project setup complete!"
echo "Next steps:"
echo "1. Create main.js and preload.js files"
echo "2. Update package.json with build configuration"
echo "3. Test your app with: npm start" 