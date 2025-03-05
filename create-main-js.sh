#!/bin/bash
# Script to create main.js for Electron app

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

# Create main.js
cat > main.js << 'EOL'
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
EOL

# Create preload.js
cat > preload.js << 'EOL'
// Preload script runs in the renderer process
window.addEventListener('DOMContentLoaded', () => {
  // You can expose APIs from here to the renderer if needed
  console.log('AutoProgrammer Desktop App loaded');
  
  // This is where you would add any custom desktop integrations
  // For example, you could add a function to save content to a file
});
EOL

echo "main.js and preload.js created successfully!" 