#!/bin/bash
# SIMPLE AUTOPROGRAMMER-CURSOR INTEGRATION
# This script has ZERO dependencies and will work immediately
# Run this script directly in a Cursor terminal

echo "=== SIMPLE AUTOPROGRAMMER-CURSOR INTEGRATION ==="
echo "This script will continuously check for AutoProgrammer outputs and display them in Cursor"
echo "Press Ctrl+C to stop"
echo ""

# Base directory is the user's system
HOME_DIR="$HOME"
DESKTOP_DIR="$HOME/Desktop"
CURRENT_DIR="$(pwd)"

# Function to find and display the most recent output file
find_and_display_output() {
  # Search in common locations
  FOUND_FILES=$(find "$CURRENT_DIR" "$HOME_DIR/Desktop" "$CURRENT_DIR/autoprogrammer-desktop" -type f -name "*output*.txt" -o -name "*autoprogrammer*.txt" -o -name "*response*.txt" -o -name "cursor-prompt.txt" -mtime -1 2>/dev/null | sort -n -t _ -k 2 | tail -10)
  
  # If no files found in common locations, try a broader search
  if [ -z "$FOUND_FILES" ]; then
    echo "Searching more broadly for recent files..."
    FOUND_FILES=$(find "$CURRENT_DIR" "$HOME_DIR/Desktop" -type f -name "*.txt" -mtime -1 2>/dev/null | grep -v "node_modules" | sort -n -t _ -k 2 | tail -10)
  fi
  
  # Debug output
  echo "Found these potential output files:"
  echo "$FOUND_FILES"
  echo ""
  
  # Find the most recent file
  NEWEST_FILE=$(echo "$FOUND_FILES" | tail -1)
  
  if [ -n "$NEWEST_FILE" ] && [ -f "$NEWEST_FILE" ]; then
    # Get file modification time
    MOD_TIME=$(stat -f "%Sm" "$NEWEST_FILE" 2>/dev/null || stat -c "%y" "$NEWEST_FILE" 2>/dev/null)
    
    # Calculate file size
    FILE_SIZE=$(wc -c < "$NEWEST_FILE" 2>/dev/null || echo "unknown")
    
    echo "=== AUTOPROGRAMMER OUTPUT ==="
    echo "SOURCE: $NEWEST_FILE"
    echo "MODIFIED: $MOD_TIME"
    echo "SIZE: $FILE_SIZE bytes"
    echo "=== CONTENT BEGINS ==="
    echo ""
    cat "$NEWEST_FILE"
    echo ""
    echo "=== CONTENT ENDS ==="
    
    # Copy to clipboard on macOS
    if command -v pbcopy >/dev/null 2>&1; then
      cat "$NEWEST_FILE" | pbcopy
      echo "✅ Content copied to clipboard"
    fi
    
    # Create a local copy for Cursor to find
    cp "$NEWEST_FILE" "$CURRENT_DIR/cursor-direct-output.txt" 2>/dev/null
    echo "✅ Content saved to cursor-direct-output.txt"
    
    return 0
  else
    echo "No AutoProgrammer output files found yet."
    echo "Waiting for output to be generated..."
    return 1
  fi
}

# Initial search
echo "Performing initial search for output files..."
find_and_display_output

# Continuous monitoring
echo ""
echo "Now watching for new outputs. Press Ctrl+C to stop."
echo "---------------------------------------------------"

while true; do
  # Wait for a bit
  sleep 3
  
  # Clear the screen for a clean display
  clear
  
  echo "Checking for new AutoProgrammer outputs... ($(date +"%H:%M:%S"))"
  find_and_display_output
  
  # Wait for a bit longer to avoid too frequent refreshes
  sleep 2
done 