#!/bin/bash
# Script to update package.json for Electron app

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

# Update package.json
cat > package.json << 'EOL'
{
  "name": "autoprogrammer-desktop",
  "version": "1.0.0",
  "description": "Desktop application for AutoProgrammer",
  "main": "main.js",
  "scripts": {
    "start": "electron .",
    "dev": "electron .",
    "build": "electron-builder build --mac",
    "build:mac": "electron-builder build --mac",
    "build:dmg": "electron-builder build --mac dmg"
  },
  "build": {
    "appId": "com.autoprogrammer.desktop",
    "productName": "AutoProgrammer",
    "mac": {
      "category": "public.app-category.developer-tools",
      "target": [
        "dmg",
        "zip"
      ],
      "icon": "icon.icns"
    },
    "extraResources": [
      {
        "from": "../autoprogrammer-ai-service",
        "to": "autoprogrammer-ai-service",
        "filter": ["**/*", "!node_modules/**"]
      },
      {
        "from": "../autoprogrammer-api",
        "to": "autoprogrammer-api",
        "filter": ["**/*", "!node_modules/**"]
      },
      {
        "from": "../autoprogrammer-ui/dist",
        "to": "autoprogrammer-ui",
        "filter": ["**/*"]
      }
    ]
  },
  "keywords": [
    "electron",
    "autoprogrammer",
    "desktop",
    "ai"
  ],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "electron": "^30.0.0",
    "electron-builder": "^24.9.1"
  },
  "dependencies": {
    "electron-is-dev": "^2.0.0"
  }
}
EOL

echo "package.json updated successfully!" 