#!/bin/bash
# This script runs the direct cursor integration script and should be executed from within Cursor

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if watch mode is requested
if [ "$1" == "--watch" ]; then
  echo "Starting in continuous watch mode. Press Ctrl+C to stop."
  echo "Will check for new outputs every 2 seconds..."
  
  # Run in watch mode
  while true; do
    node "$SCRIPT_DIR/direct-cursor-integration.js" --watch
    sleep 2
  done
else
  # Run the direct integration script once
  echo "Running one-time check for AutoProgrammer output..."
  node "$SCRIPT_DIR/direct-cursor-integration.js"
  
  echo ""
  echo "✅ Finished checking for AutoProgrammer output"
  echo "To continuously monitor for new outputs, run: ./run-in-cursor.sh --watch"
fi 