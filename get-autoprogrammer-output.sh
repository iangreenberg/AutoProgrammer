#!/bin/bash
# Script to manually get the latest AutoProgrammer output

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the direct integration script once
node "$SCRIPT_DIR/direct-cursor-integration.js"

echo ""
echo "✅ Latest AutoProgrammer output retrieved"
echo "If you want continuous monitoring, run './run-in-cursor.sh' in a Cursor terminal" 