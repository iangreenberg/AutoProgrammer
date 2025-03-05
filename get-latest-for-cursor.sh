#!/bin/bash

# AutoProgrammer output retriever for Cursor
# This script retrieves the latest output from AutoProgrammer and formats it for Cursor

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Go to the desktop app directory
cd "$SCRIPT_DIR/autoprogrammer-desktop"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js to use this script."
    exit 1
fi

# Run the cursor agent helper script
node cursor-agent-helper.js

# If you need to clear the outputs, uncomment this line:
# node check-cursor-output.js clear

echo ""
echo "This output is from AutoProgrammer. You can now use this content as input for your Cursor prompts."
echo "To generate new outputs, use the AutoProgrammer desktop app and click 'Save to Cursor'." 