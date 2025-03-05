#!/bin/bash
# ULTRA SIMPLE AUTOPROGRAMMER OUTPUT FINDER
# Just run this in Cursor to see the most recent output

echo "🔍 Searching for AutoProgrammer outputs..."

# Base directory is the user's system
HOME_DIR="$HOME"
DESKTOP_DIR="$HOME/Desktop"
CURRENT_DIR="$(pwd)"

# Search for recent output files (modified in the last 24 hours)
echo "Searching in common locations..."
FOUND_FILES=$(find "$CURRENT_DIR" "$HOME_DIR/Desktop" "$CURRENT_DIR/autoprogrammer-desktop" -type f -name "*output*.txt" -o -name "*autoprogrammer*.txt" -o -name "*response*.txt" -o -name "cursor-prompt.txt" -mtime -1 2>/dev/null)

# If no files found in common locations, try a broader search
if [ -z "$FOUND_FILES" ]; then
  echo "Searching more broadly..."
  FOUND_FILES=$(find "$CURRENT_DIR" "$DESKTOP_DIR" -type f -name "*.txt" -mtime -1 2>/dev/null | grep -v "node_modules")
fi

# Show all found files, sorted by modification time (newest last)
echo "------------------------------"
echo "Found these files:"
echo "------------------------------"
ls -lt $(echo "$FOUND_FILES") 2>/dev/null

# Find newest file
NEWEST_FILE=$(ls -t $(echo "$FOUND_FILES") 2>/dev/null | head -1)

if [ -n "$NEWEST_FILE" ] && [ -f "$NEWEST_FILE" ]; then
  echo ""
  echo "============================="
  echo "MOST RECENT OUTPUT:"
  echo "============================="
  echo "File: $NEWEST_FILE"
  echo "------------------------------"
  echo ""
  cat "$NEWEST_FILE"
  echo ""
  echo "============================="
  
  # Copy to clipboard on macOS
  if command -v pbcopy >/dev/null 2>&1; then
    cat "$NEWEST_FILE" | pbcopy
    echo "✅ Content copied to clipboard!"
  fi
else
  echo ""
  echo "❌ No AutoProgrammer output files found."
  echo "Make sure AutoProgrammer has generated a response."
fi 