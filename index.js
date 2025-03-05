/**
 * AutoProgrammer main entry point
 * This is the main process when running with Electron
 */

const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
require('dotenv').config();

// Global reference to prevent garbage collection
let mainWindow;
let outputServiceProcess;
let cursorIntegrationProcess;

// Handle unhandled exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

// Check and create necessary directories
function ensureDirectories() {
  const dirs = [
    './outputs',
    './outputs/processed',
    './logs'
  ];
  
  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
      console.log(`Created directory: ${dir}`);
    }
  });
}

// Start the output service microservice
function startOutputService() {
  const outputServicePath = path.join(__dirname, 'services', 'output-service.js');
  if (!fs.existsSync(outputServicePath)) {
    console.error(`Output service not found at: ${outputServicePath}`);
    return null;
  }
  
  console.log('Starting output service...');
  const process = spawn('node', [outputServicePath], {
    stdio: 'pipe',
    detached: false
  });
  
  process.stdout.on('data', (data) => {
    console.log(`[OUTPUT-SERVICE] ${data.toString().trim()}`);
  });
  
  process.stderr.on('data', (data) => {
    console.error(`[OUTPUT-SERVICE-ERROR] ${data.toString().trim()}`);
  });
  
  process.on('error', (error) => {
    console.error('Failed to start output service:', error);
  });
  
  return process;
}

// Start the cursor integration script
function startCursorIntegration() {
  let scriptPath;
  
  // Try different integration scripts, from simplest to more complex
  const possibleScripts = [
    path.join(__dirname, 'last-resort.command'),
    path.join(__dirname, 'super-simple.sh')
  ];
  
  for (const script of possibleScripts) {
    if (fs.existsSync(script)) {
      scriptPath = script;
      break;
    }
  }
  
  if (!scriptPath) {
    console.error('No integration script found');
    return null;
  }
  
  console.log(`Starting cursor integration: ${scriptPath}`);
  const process = spawn('/bin/bash', [scriptPath], {
    stdio: 'pipe',
    detached: false
  });
  
  process.stdout.on('data', (data) => {
    console.log(`[CURSOR-INTEGRATION] ${data.toString().trim()}`);
  });
  
  process.stderr.on('data', (data) => {
    console.error(`[CURSOR-INTEGRATION-ERROR] ${data.toString().trim()}`);
  });
  
  process.on('error', (error) => {
    console.error('Failed to start cursor integration:', error);
  });
  
  return process;
}

// Create the main window
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });
  
  // Load a simple HTML interface
  mainWindow.loadFile(path.join(__dirname, 'index.html'));
  
  // Open DevTools in development
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }
  
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// Initialize when Electron is ready
app.whenReady().then(() => {
  console.log('Starting AutoProgrammer...');
  
  // Setup required directories
  ensureDirectories();
  
  // Start microservices
  outputServiceProcess = startOutputService();
  cursorIntegrationProcess = startCursorIntegration();
  
  // Create window after a short delay to allow services to start
  setTimeout(createWindow, 1000);
  
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

// Quit when all windows are closed, except on macOS
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Clean up processes on quit
app.on('will-quit', () => {
  console.log('Shutting down AutoProgrammer...');
  
  if (outputServiceProcess) {
    outputServiceProcess.kill();
  }
  
  if (cursorIntegrationProcess) {
    cursorIntegrationProcess.kill();
  }
}); 