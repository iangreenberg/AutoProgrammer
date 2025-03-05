#!/bin/bash
# ONE-CLICK SOLUTION FOR AUTOPROGRAMMER-CURSOR INTEGRATION
# Just double-click this file to start the integration
# This file has the .command extension so it can be easily run on macOS

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "======================================================"
echo "  ONE-CLICK AUTOPROGRAMMER-CURSOR SOLUTION"
echo "  Starting automatic integration now..."
echo "======================================================"

# Create the direct solution script if it doesn't exist
if [ ! -f "$DIR/direct-cursor-solution.sh" ]; then
  cat > "$DIR/direct-cursor-solution.sh" << 'EOL'
#!/bin/bash
# DIRECT SOLUTION: AutoProgrammer to Cursor Integration
# This is a completely standalone solution that doesn't depend on Electron
# Just run this script and it will continuously monitor for outputs

echo "======================================================"
echo "  DIRECT AUTOPROGRAMMER-CURSOR SOLUTION ACTIVATED"
echo "  No dependencies, no complex setup, just works!"
echo "======================================================"

# Important directories
CURRENT_DIR="$(pwd)"
HOME_DIR="$HOME"
DESKTOP_DIR="$HOME/Desktop"
DOCUMENTS_DIR="$HOME/Documents"
DOWNLOADS_DIR="$HOME/Downloads" 

# Create a cursor output file in the current directory
CURSOR_OUTPUT_FILE="$CURRENT_DIR/direct-cursor-output.txt"
touch "$CURSOR_OUTPUT_FILE"

# Initialize output tracking
LAST_OUTPUT_CONTENT=""

# Function to find all potential output files across the system
find_output_files() {
  find "$CURRENT_DIR" "$DESKTOP_DIR" "$DOCUMENTS_DIR" "$DOWNLOADS_DIR" -type f \
    \( -name "*output*.txt" -o -name "*response*.txt" -o -name "*autoprogrammer*.txt" -o -name "cursor-*.txt" \) \
    -mmin -60 2>/dev/null | sort
}

# Function to display content in the terminal and copy to clipboard
display_and_copy() {
  local content="$1"
  local source="$2"
  
  # Only process if content has changed
  if [ "$content" != "$LAST_OUTPUT_CONTENT" ]; then
    # Clear terminal for clean output
    clear
    
    echo "======================================================"
    echo "NEW AUTOPROGRAMMER OUTPUT DETECTED!"
    echo "Source: $source"
    echo "Time: $(date)"
    echo "======================================================"
    echo ""
    echo "$content"
    echo ""
    echo "======================================================"
    echo "✓ Output detected and displayed in Cursor terminal"
    
    # Save to our direct output file
    echo "$content" > "$CURSOR_OUTPUT_FILE"
    
    # Copy to clipboard on macOS
    if command -v pbcopy >/dev/null 2>&1; then
      echo "$content" | pbcopy
      echo "✓ Output copied to clipboard"
    fi
    
    # Update tracking variable
    LAST_OUTPUT_CONTENT="$content"
    
    return 0
  fi
  
  return 1
}

# Main monitoring loop
echo "Searching for AutoProgrammer outputs..."
echo "This will continuously monitor for new outputs"
echo "Press Ctrl+C to stop"
echo ""

while true; do
  # Find all potential output files
  OUTPUT_FILES=$(find_output_files)
  
  # Check if any files were found
  if [ -n "$OUTPUT_FILES" ]; then
    # Find the most recent file
    NEWEST_FILE=$(ls -t $OUTPUT_FILES 2>/dev/null | head -1)
    
    if [ -n "$NEWEST_FILE" ] && [ -f "$NEWEST_FILE" ]; then
      # Get content and display if new
      CONTENT=$(cat "$NEWEST_FILE")
      if display_and_copy "$CONTENT" "$NEWEST_FILE"; then
        # Displayed new content, wait a bit longer before next check
        sleep 5
      fi
    fi
  fi
  
  # Status indicator (shows the script is still running)
  echo -n "." >&2
  
  # Wait before checking again
  sleep 2
done
EOL

  # Make the script executable
  chmod +x "$DIR/direct-cursor-solution.sh"
  echo "Created direct-cursor-solution.sh"
fi

# Run the direct solution
"$DIR/direct-cursor-solution.sh" 