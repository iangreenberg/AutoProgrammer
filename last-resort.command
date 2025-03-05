#!/bin/bash
# LAST RESORT - ABSOLUTELY MINIMAL APPROACH
# Double-click this file to start

# Go to the script directory
cd "$(dirname "$0")" || exit

echo "LOOKING FOR ANY TEXT FILES ON YOUR DESKTOP OR HERE"
echo "This will find ANY text files modified recently"
echo "---------------------------------------------"

# Just check two places: current dir and desktop
DESKTOP="$HOME/Desktop"

# Very simple loop to check for new files
LAST_FILE=""

while true; do
  # Find recent text files (last 10 minutes)
  FOUND=$(find "$DESKTOP" "$(pwd)" -name "*.txt" -mmin -10 -type f 2>/dev/null | sort)
  
  # Get newest file
  NEWEST=$(echo "$FOUND" | tail -1)
  
  # If file exists and is different from last one
  if [ -f "$NEWEST" ] && [ "$NEWEST" != "$LAST_FILE" ]; then
    clear
    echo "NEW FILE FOUND: $NEWEST"
    echo "---------------------------------------------"
    echo ""
    
    # Show content
    cat "$NEWEST"
    echo ""
    echo "---------------------------------------------"
    
    # Copy to clipboard
    cat "$NEWEST" | pbcopy
    echo "Copied to clipboard"
    
    # Remember this file
    LAST_FILE="$NEWEST"
    
    # Pause after finding a file
    sleep 3
  else
    # Show that we're still working
    echo -n "."
  fi
  
  # Brief pause between checks
  sleep 1
done 