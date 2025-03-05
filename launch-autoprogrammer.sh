#!/bin/bash
# FIX FOR AUTOPROGRAMMER ELECTRON ISSUES
# This script launches AutoProgrammer with the correct Electron path
# and starts the integration automatically

# Path to AutoProgrammer
APP_DIR="/Users/iangreenberg/Desktop/AutoProgrammer"

# Absolute path to Electron (confirmed it exists)
ELECTRON_PATH="/usr/local/bin/electron"

echo "==== LAUNCHING AUTOPROGRAMMER WITH INTEGRATION ===="
echo "Starting AutoProgrammer application..."

# Go to application directory
cd "$APP_DIR"

# Launch AutoProgrammer with absolute Electron path
"$ELECTRON_PATH" . &
APP_PID=$!

# Wait a moment for app to initialize
sleep 2

# Start the integration script in background
echo "Starting integration script..."
"$APP_DIR/simple-cursor-integration.sh" &
INTEGRATION_PID=$!

echo "AutoProgrammer running with PID: $APP_PID"
echo "Integration running with PID: $INTEGRATION_PID"
echo "==================================================="
echo "Everything is now running automatically!"
echo "You can close this terminal window if desired."
echo "==================================================="

# Keep script running so it doesn't terminate the background processes
wait $APP_PID 