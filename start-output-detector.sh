#!/bin/bash
# Start the AutoProgrammer Output Detector

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Starting AutoProgrammer Output Detector..."

# Check if the required package is installed
echo "Checking dependencies..."
if ! npm list chokidar | grep -q chokidar; then
    echo "Installing required npm package 'chokidar'..."
    npm install chokidar
fi

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is required but not installed."
    echo "Please install Node.js and try again."
    exit 1
fi

# Check if the detector script exists
if [ ! -f "$SCRIPT_DIR/auto-output-detector.js" ]; then
    echo "Error: auto-output-detector.js not found."
    echo "Please make sure you are running this script from the correct directory."
    exit 1
fi

# Create a lock file to prevent multiple instances
LOCK_FILE="$SCRIPT_DIR/.output-detector.lock"
if [ -f "$LOCK_FILE" ]; then
    # Check if the process is still running
    if ps -p $(cat "$LOCK_FILE") > /dev/null 2>&1; then
        echo "Output detector is already running with PID: $(cat "$LOCK_FILE")"
        echo "To start a new instance, first kill the existing one or run:"
        echo "rm $LOCK_FILE"
        exit 1
    else
        # Process is not running, so remove the lock file
        rm "$LOCK_FILE" 2>/dev/null
    fi
fi

# Start the detector and save its PID
node "$SCRIPT_DIR/auto-output-detector.js" &
DETECTOR_PID=$!
echo $DETECTOR_PID > "$LOCK_FILE"

echo "Output detector started with PID: $DETECTOR_PID"
echo "This process will automatically detect any AutoProgrammer outputs and make them available to Cursor."

# Provide integration tips
echo ""
echo "=== IMPORTANT NOTES ==="
echo "• The detector will continuously monitor for new outputs."
echo "• To stop it, run: kill $DETECTOR_PID"
echo "• For immediate output access in Cursor, run:"
echo "  ./run-in-cursor.sh --watch"
echo ""
echo "✅ Output detector is now active and monitoring for outputs."
echo "You can now use AutoProgrammer, and any outputs will be automatically detected." 