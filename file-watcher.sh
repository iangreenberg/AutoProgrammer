#!/bin/bash
# SIMPLE FILE WATCHER FOR AUTOPROGRAMMER
# This script monitors directories for changes using basic bash
# No dependencies required!

# Directories to monitor
CURRENT_DIR="$(pwd)"
DESKTOP_DIR="$HOME/Desktop"
APP_DIR="$CURRENT_DIR/autoprogrammer-desktop"

echo "==========================="
echo "AUTOPROGRAMMER FILE WATCHER"
echo "==========================="
echo "Watching for new files in:"
echo "- $CURRENT_DIR"
echo "- $DESKTOP_DIR"
echo "- $APP_DIR"
echo ""
echo "When a new file is detected, it will be displayed."
echo "Press Ctrl+C to stop watching."
echo "==========================="

# Function to create a checksum of all files in a directory (for change detection)
get_dir_checksum() {
  find "$1" -type f -name "*.txt" -mtime -1 -print0 2>/dev/null | xargs -0 ls -la 2>/dev/null | md5
}

# Initial checksums
CHECKSUM_CURRENT=$(get_dir_checksum "$CURRENT_DIR")
CHECKSUM_DESKTOP=$(get_dir_checksum "$DESKTOP_DIR")
CHECKSUM_APP=$(get_dir_checksum "$APP_DIR")

while true; do
  # Wait a bit (not too fast to avoid high CPU usage)
  sleep 2
  
  # Get new checksums
  NEW_CHECKSUM_CURRENT=$(get_dir_checksum "$CURRENT_DIR")
  NEW_CHECKSUM_DESKTOP=$(get_dir_checksum "$DESKTOP_DIR")
  NEW_CHECKSUM_APP=$(get_dir_checksum "$APP_DIR")
  
  # Check for changes
  if [ "$NEW_CHECKSUM_CURRENT" != "$CHECKSUM_CURRENT" ] || 
     [ "$NEW_CHECKSUM_DESKTOP" != "$CHECKSUM_DESKTOP" ] || 
     [ "$NEW_CHECKSUM_APP" != "$CHECKSUM_APP" ]; then
    
    # Change detected!
    echo ""
    echo "🔔 CHANGE DETECTED! $(date '+%H:%M:%S')"
    echo "--------------------------"
    
    # Find the newest file
    NEWEST_FILE=$(find "$CURRENT_DIR" "$DESKTOP_DIR" "$APP_DIR" -type f -name "*.txt" -mtime -1 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
    
    if [ -n "$NEWEST_FILE" ] && [ -f "$NEWEST_FILE" ]; then
      echo "New/Changed file: $NEWEST_FILE"
      echo ""
      echo "=== CONTENT ==="
      cat "$NEWEST_FILE"
      echo "=============="
      
      # Copy to clipboard
      if command -v pbcopy >/dev/null 2>&1; then
        cat "$NEWEST_FILE" | pbcopy
        echo "✅ Content copied to clipboard!"
      fi
    else
      echo "Unable to find the changed file."
    fi
    
    # Update checksums
    CHECKSUM_CURRENT="$NEW_CHECKSUM_CURRENT"
    CHECKSUM_DESKTOP="$NEW_CHECKSUM_DESKTOP"
    CHECKSUM_APP="$NEW_CHECKSUM_APP"
  else
    # No change, print a reassuring dot
    echo -n "."
  fi
done 