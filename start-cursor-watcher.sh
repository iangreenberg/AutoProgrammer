#!/bin/bash

# Cursor Watcher Starter
# This script starts the Cursor watcher that automatically monitors
# for AutoProgrammer outputs and inserts them into Cursor

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Starting Cursor watcher..."

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is required but not installed."
    echo "Please install Node.js and try again."
    exit 1
fi

# Check if the cursor-watcher.js script exists
if [ ! -f "$SCRIPT_DIR/cursor-watcher.js" ]; then
    echo "Error: cursor-watcher.js not found."
    echo "Please make sure you are running this script from the correct directory."
    exit 1
fi

# Create a lock file to prevent multiple instances
LOCK_FILE="$SCRIPT_DIR/.cursor-watcher.lock"
if [ -f "$LOCK_FILE" ]; then
    # Check if the process is still running
    if ps -p $(cat "$LOCK_FILE") > /dev/null 2>&1; then
        echo "Cursor watcher is already running with PID: $(cat "$LOCK_FILE")"
        echo "To start a new instance, first kill the existing one or run:"
        echo "rm $LOCK_FILE"
        exit 1
    else
        # Process is not running, so remove the lock file
        rm "$LOCK_FILE" 2>/dev/null
    fi
fi

# Start the cursor watcher and save its PID
node "$SCRIPT_DIR/cursor-watcher.js" &
WATCHER_PID=$!
echo $WATCHER_PID > "$LOCK_FILE"

echo "Cursor watcher started with PID: $WATCHER_PID"
echo "This process will watch for new outputs and insert them into Cursor."

# Provide integration tips
echo ""
echo "=== IMPORTANT NOTES ==="
echo "• The watcher will run for 30 minutes and then automatically stop to save resources."
echo "• You can restart it at any time by running this script again."
echo "• For the most reliable integration, use the direct in-Cursor method instead:"
echo "  ./run-in-cursor.sh"
echo ""
echo "✅ Cursor watcher is now active and monitoring for outputs." 