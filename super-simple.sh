#!/bin/bash
# SUPER SIMPLE - ABSOLUTELY NO COMPLEXITY
# This is the most basic solution possible

echo "===== SUPER SIMPLE SOLUTION STARTED ====="
echo "This will just find and show any txt files"

# Just check two places: current directory and desktop
DESKTOP="$HOME/Desktop"
HERE="$(pwd)"

# Show exactly what we're doing
echo "Looking in: $HERE and $DESKTOP"
echo "Press Ctrl+C to stop"
echo ""

# Set initial state
LAST_FOUND=""

# Super simple loop
while true; do
  echo -n "." # Activity indicator
  
  # Find ANY txt files modified in last 10 minutes
  # Simplest possible search
  FOUND_FILES=$(find "$HERE" "$DESKTOP" -name "*.txt" -mmin -10 -type f 2>/dev/null | sort)
  
  # If we found any files
  if [ -n "$FOUND_FILES" ]; then
    # Get the newest one
    NEWEST=$(echo "$FOUND_FILES" | tail -1)
    
    # If it's different from the last one we processed
    if [ "$NEWEST" != "$LAST_FOUND" ] && [ -f "$NEWEST" ]; then
      clear
      echo "===== FOUND A NEW TEXT FILE! ====="
      echo "File: $NEWEST"
      echo ""
      
      # Show the content
      cat "$NEWEST"
      echo ""
      echo "===== END OF CONTENT ====="
      
      # Save this as the last found file
      LAST_FOUND="$NEWEST"
      
      # Copy to clipboard
      if command -v pbcopy >/dev/null 2>&1; then
        cat "$NEWEST" | pbcopy
        echo "Content copied to clipboard"
      fi
      
      # Wait a little longer after finding something
      sleep 3
    fi
  fi
  
  # Brief pause
  sleep 1
done 