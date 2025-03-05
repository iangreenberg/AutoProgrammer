#!/bin/bash

# AutoProgrammer Cursor Integration
# This script starts the AutoProgrammer desktop app and Cursor integration

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Starting AutoProgrammer Cursor Integration..."

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is required but not installed."
    echo "Please install Node.js and try again."
    exit 1
fi

# Start the auto-import process in the background
echo "Starting auto-import process..."
node "$SCRIPT_DIR/auto-cursor-import.js" &
AUTO_IMPORT_PID=$!

# Save the PID to a file for later termination
echo $AUTO_IMPORT_PID > "$SCRIPT_DIR/.auto-import.pid"

echo "Auto-import process started with PID: $AUTO_IMPORT_PID"
echo "This process will monitor AutoProgrammer outputs and make them available to Cursor."

# Provide instructions for Cursor integration
echo ""
echo "=== NEXT STEPS ==="
echo "1. Open Cursor and start using AutoProgrammer"
echo "2. For the most reliable integration, open a terminal in Cursor and run:"
echo "   ./run-in-cursor.sh"
echo ""
echo "3. Alternatively, you can start the external watcher with:"
echo "   ./start-cursor-watcher.sh"
echo ""
echo "4. To manually get the latest output at any time, run:"
echo "   ./get-autoprogrammer-output.sh"

# Start AutoProgrammer desktop app if available
if [ -f "$SCRIPT_DIR/autoprogrammer-desktop/AutoProgrammer" ]; then
    echo ""
    echo "Starting AutoProgrammer desktop app..."
    "$SCRIPT_DIR/autoprogrammer-desktop/AutoProgrammer" &
elif [ -d "$SCRIPT_DIR/autoprogrammer-desktop" ]; then
    echo ""
    echo "AutoProgrammer desktop app detected but executable not found."
    echo "Please start AutoProgrammer manually."
else
    echo ""
    echo "AutoProgrammer desktop app not found."
    echo "Please start AutoProgrammer manually."
fi

echo ""
echo "✅ Cursor integration setup complete!"
echo "The integration will continue running in the background." 