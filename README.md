# AutoProgrammer

A microservices-based AI-powered programming assistant that helps developers generate code and solve software engineering problems.

## System Architecture

AutoProgrammer consists of three main microservices:

1. **AI Service** - Core AI processing service that communicates with the DeepSeek API to generate code and answers.
2. **API Gateway** - REST API that handles requests from clients and communicates with the AI Service.
3. **UI** - React-based web interface that allows users to interact with the system.

```
┌─────────────────┐      ┌─────────────────┐     ┌─────────────────┐
│                 │      │                 │     │                 │
│       UI        │─────▶│   API Gateway   │────▶│    AI Service   │
│  (Port: 5173)   │      │   (Port: 4000)  │     │   (Port: 5000)  │
│                 │◀─────│                 │◀────│                 │
└─────────────────┘      └─────────────────┘     └─────────────────┘
```

## Prerequisites

- Node.js v18+ and npm
- DeepSeek API key (for production use)
- Git
- macOS (for building macOS app)

## Quick Start

The easiest way to start all services is to use the included start script:

```bash
./start-autoprogrammer.sh
```

This will:
1. Stop any existing services on ports 5000, 4000, and 5173
2. Configure environment variables for all services
3. Start all services in the correct order
4. Create a stop script for shutting down services

Once started, you can access:
- UI: http://localhost:5173
- API Gateway: http://localhost:4000
- AI Service: http://localhost:5000

## Manual Setup

If you prefer to start services manually:

### 1. AI Service

```bash
cd autoprogrammer-ai-service
npm install
NODE_ENV=development npm run dev
```

### 2. API Gateway

```bash
cd autoprogrammer-api
npm install
NODE_ENV=development npm run dev
```

### 3. UI

```bash
cd autoprogrammer-ui
npm install
npm run dev
```

## Configuration

Each service uses environment variables for configuration:

### AI Service (.env)

```
NODE_ENV=development
PORT=5000
API_GATEWAY_URL=http://localhost:4000
DEEPSEEK_API_KEY=your-api-key-here
DEEPSEEK_MODEL=deepseek-coder
```

### API Gateway (.env)

```
NODE_ENV=development
PORT=4000
AI_SERVICE_URL=http://localhost:5000
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:5174
SKIP_API_VALIDATION=true
```

### UI (.env)

```
VITE_API_GATEWAY_URL=http://localhost:4000
VITE_NODE_ENV=development
```

## Troubleshooting

### Logs

Service logs are saved to the following files:
- AI Service: `ai-service.log`
- API Gateway: `api-gateway.log`
- UI: `ui.log`

### Common Issues

1. **Port conflicts** - Make sure ports 5000, 4000, and 5173 are available or configure services to use different ports.
2. **Connection errors** - Check if all services are running and can connect to each other.
3. **DeepSeek API errors** - Verify your API key and model name in the AI Service configuration.
4. **Blank UI page** - Try clearing your browser cache and restarting the UI service.

### Troubleshooting Summary

The following scripts have been created to help troubleshoot and fix common issues:

1. **fix-ui-advanced.sh** - Comprehensive script to fix UI blank page issues:
   - Stops all services and frees ports
   - Rebuilds UI dependencies
   - Creates enhanced debugging tools
   - Restarts all services in the correct order
   - Provides detailed diagnostic pages at `/debug-ui.html` and `/minimal-react.html`

2. **update-react.sh** - Downgrades React from experimental v19 to stable v18.2.0:
   - Addresses compatibility issues that may cause blank pages
   - Updates package.json and reinstalls dependencies
   - Restarts the UI service

3. **fix-deepseek.sh** - Updates the DeepSeek model configuration:
   - Allows switching between different DeepSeek models
   - Updates API key configuration
   - Restarts the AI service

4. **restart-services.sh** - Safely restarts all microservices:
   - Stops services in the correct order
   - Frees ports if needed
   - Restarts services with proper environment variables
   - Logs startup information

5. **check-health.sh** - Checks the health of all services:
   - Tests connectivity between services
   - Verifies API endpoints
   - Reports status of each service

For advanced debugging of UI issues, the following diagnostic pages are available:
- `/debug-ui.html` - Comprehensive UI debugging tools
- `/minimal-react.html` - Minimal React test page
- `/reset-browser.html` - Helps reset browser cache and storage

If you encounter issues with the React UI, try using the stable React 18.2.0 version instead of the experimental React 19, as it provides better compatibility with the current codebase.

## Development

### Project Structure

```
autoprogrammer/
├── autoprogrammer-ai-service/   # AI Service
├── autoprogrammer-api/          # API Gateway
├── autoprogrammer-ui/           # User Interface
├── start-autoprogrammer.sh      # Start script
└── stop-autoprogrammer.sh       # Stop script
```

### Adding Features

Follow microservice best practices when adding features:
- Keep services independent and loosely coupled
- Use environment variables for configuration
- Add comprehensive logging
- Document API endpoints
- Handle errors gracefully

## License

MIT License

# AutoProgrammer Desktop App

This is a desktop wrapper for the AutoProgrammer application using Electron.

## Prerequisites

- Node.js and npm installed
- Git
- macOS (for building macOS app)

## Setup

1. **Clone the AutoProgrammer repository** (if you haven't already)

```bash
git clone https://github.com/yourusername/autoprogrammer.git
cd autoprogrammer
```

2. **Create a new directory for the desktop app:**

```bash
mkdir -p autoprogrammer-desktop
cd autoprogrammer-desktop
```

3. **Initialize the project:**

```bash
npm init -y
npm install electron electron-builder --save-dev
npm install electron-is-dev --save
```

4. **Create the main.js file:**

This file will handle starting all the microservices and creating the Electron window.

```javascript
// Copy the content from the main.js file in this repository
```

5. **Create the preload.js file:**

```javascript
// Preload script runs in the renderer process
window.addEventListener('DOMContentLoaded', () => {
  // You can expose APIs from here to the renderer if needed
  console.log('AutoProgrammer Desktop App loaded');
  
  // This is where you would add any custom desktop integrations
  // For example, you could add a function to save content to a file
});
```

6. **Update package.json:**

```json
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
  }
}
```

## Development

To run the application in development mode:

```bash
npm start
```

## Building the macOS App

1. First, build the UI:

```bash
cd ../autoprogrammer-ui
npm run build
```

2. Then build the Electron app:

```bash
cd ../autoprogrammer-desktop
npm run build:mac
```

The built application will be available in the `dist` directory.

## Creating an Installer

To create a DMG installer:

```bash
npm run build:dmg
```

## Notes

- This is configured to include your DeepSeek API key (`sk-4556dc93bbe54e9b8ea29d0e655eb641`) in the application.
- The app starts all three microservices: AI Service, API Gateway, and UI.
- All connections are kept local (localhost). 