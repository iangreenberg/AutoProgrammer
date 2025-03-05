# AutoProgrammer macOS App Build Guide

This guide will walk you through converting your AutoProgrammer web application into a standalone macOS application using Electron.

## Prerequisites

- Node.js and npm installed
- macOS for building the application
- Xcode installed (for notarization)
- Apple Developer account (for code signing)

## Step 1: Setup the Electron Project

1. Create a new directory for the desktop app:
```bash
mkdir -p autoprogrammer-desktop
cd autoprogrammer-desktop
```

2. Initialize a new npm project and install required dependencies:
```bash
npm init -y
npm install electron electron-builder --save-dev
npm install electron-is-dev --save
```

## Step 2: Create the Core Files

Create the following files in your autoprogrammer-desktop directory:

### main.js
```javascript
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const isDev = require('electron-is-dev');
const fs = require('fs');

// Base directory for the original AutoProgrammer
const baseDir = path.join(__dirname, '..');
const logDir = path.join(__dirname, 'logs');

// Create logs directory if it doesn't exist
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// Keep references to prevent garbage collection
let mainWindow;
let aiServiceProcess;
let apiGatewayProcess;
let uiProcess;

// Manage logging for all services
const createLogFile = (serviceName) => {
  return fs.createWriteStream(path.join(logDir, `${serviceName}.log`), { flags: 'a' });
};

// Function to start all the backend services
function startBackendServices() {
  console.log('Starting backend services...');
  
  // Start AI Service
  console.log('Starting AI Service...');
  const aiServicePath = path.join(baseDir, 'autoprogrammer-ai-service');
  
  // Create/update environment file
  const aiServiceEnv = `NODE_ENV=development
PORT=5000
API_GATEWAY_URL=http://localhost:4000
DEEPSEEK_API_KEY=sk-4556dc93bbe54e9b8ea29d0e655eb641
DEEPSEEK_MODEL=deepseek-coder
USE_MOCK_IN_DEV=false
`;
  fs.writeFileSync(path.join(aiServicePath, '.env'), aiServiceEnv);

  // Start process
  aiServiceProcess = spawn('npm', ['run', 'dev'], {
    cwd: aiServicePath,
    env: Object.assign({}, process.env, { NODE_ENV: 'development' }),
    shell: true
  });
  
  // Set up logging
  const aiServiceLog = createLogFile('ai-service');
  aiServiceProcess.stdout.pipe(aiServiceLog);
  aiServiceProcess.stderr.pipe(aiServiceLog);
  
  aiServiceProcess.on('error', (error) => {
    console.error('Failed to start AI Service:', error);
  });

  // Start API Gateway
  console.log('Starting API Gateway...');
  const apiGatewayPath = path.join(baseDir, 'autoprogrammer-api');
  
  // Create/update environment file
  const apiGatewayEnv = `NODE_ENV=development
PORT=4000
AI_SERVICE_URL=http://localhost:5000
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:5174
SKIP_API_VALIDATION=true
`;
  fs.writeFileSync(path.join(apiGatewayPath, '.env'), apiGatewayEnv);

  // Start process
  apiGatewayProcess = spawn('npm', ['run', 'dev'], {
    cwd: apiGatewayPath,
    env: Object.assign({}, process.env, { NODE_ENV: 'development' }),
    shell: true
  });
  
  // Set up logging
  const apiGatewayLog = createLogFile('api-gateway');
  apiGatewayProcess.stdout.pipe(apiGatewayLog);
  apiGatewayProcess.stderr.pipe(apiGatewayLog);
  
  apiGatewayProcess.on('error', (error) => {
    console.error('Failed to start API Gateway:', error);
  });

  // Start UI (Vite development server)
  console.log('Starting UI...');
  const uiPath = path.join(baseDir, 'autoprogrammer-ui');
  
  // Create/update environment file
  const uiEnv = `VITE_API_GATEWAY_URL=http://localhost:4000
VITE_NODE_ENV=development
`;
  fs.writeFileSync(path.join(uiPath, '.env'), uiEnv);

  // Start process
  uiProcess = spawn('npm', ['run', 'dev'], {
    cwd: uiPath,
    env: Object.assign({}, process.env, { NODE_ENV: 'development' }),
    shell: true
  });
  
  // Set up logging
  const uiLog = createLogFile('ui');
  uiProcess.stdout.pipe(uiLog);
  uiProcess.stderr.pipe(uiLog);
  
  uiProcess.on('error', (error) => {
    console.error('Failed to start UI:', error);
  });
}

// Function to create the main window
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      preload: path.join(__dirname, 'preload.js')
    },
    title: 'AutoProgrammer',
  });

  // Wait for Vite server to start
  setTimeout(() => {
    mainWindow.loadURL('http://localhost:5173');
    
    if (isDev) {
      mainWindow.webContents.openDevTools();
    }
  }, 5000); // Give services 5 seconds to start

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// Start the app
app.on('ready', () => {
  startBackendServices();
  createWindow();
});

// Quit when all windows are closed
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});

// Clean up processes on exit
app.on('will-quit', () => {
  console.log('Shutting down services...');
  
  if (aiServiceProcess) {
    aiServiceProcess.kill();
  }
  
  if (apiGatewayProcess) {
    apiGatewayProcess.kill();
  }
  
  if (uiProcess) {
    uiProcess.kill();
  }
});
```

### preload.js
```javascript
// Preload script runs in the renderer process
window.addEventListener('DOMContentLoaded', () => {
  // You can expose APIs from here to the renderer if needed
  console.log('AutoProgrammer Desktop App loaded');
  
  // This is where you would add any custom desktop integrations
  // For example, you could add a function to save content to a file
});
```

### package.json
Replace the content of your package.json with the following:

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
```

## Step 3: Test the Application

1. Start the application in development mode:
```bash
npm start
```

This should launch your AutoProgrammer application in an Electron window.

## Step 4: Build the Application

1. Build the React UI first:
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

## Step 5: Code Signing (Optional)

For distribution, you'll want to sign your application. This requires an Apple Developer account.

1. Add these fields to the `mac` section in your package.json:
```json
"mac": {
  "hardenedRuntime": true,
  "gatekeeperAssess": false,
  "entitlements": "entitlements.plist",
  "entitlementsInherit": "entitlements.plist",
  "identity": "Your Apple Developer ID"
}
```

2. Create entitlements.plist:
```xml
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
```

## Step 6: Create a DMG Installer

Run the following command to create a DMG installer:
```bash
npm run build:dmg
```

## Notes

- This setup ensures your API key `sk-4556dc93bbe54e9b8ea29d0e655eb641` is included in the application.
- All services run locally within the Electron app.
- For security in a production app, you might want to use a more secure way to store the API key.

## Troubleshooting

- If you encounter the "App can't be opened because it is from an unidentified developer" error, you can right-click the app and select "Open" to bypass Gatekeeper.
- Make sure all node_modules dependencies are installed in each service's directory. 