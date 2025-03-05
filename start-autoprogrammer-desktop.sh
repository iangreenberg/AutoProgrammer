#!/bin/bash

# Start AutoProgrammer Desktop App
# This script ensures the app starts correctly even if electron isn't globally installed

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Go to the desktop app directory
cd "$SCRIPT_DIR/autoprogrammer-desktop"

# Check if npx is installed
if ! command -v npx &> /dev/null; then
    echo "Error: npx is not installed. Please install Node.js and npm to use this script."
    exit 1
fi

# Start the app using npx to ensure electron is found
echo "Starting AutoProgrammer Desktop App..."
npx electron . 