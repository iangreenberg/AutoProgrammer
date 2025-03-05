#!/bin/bash
# Setup AutoProgrammer to start automatically with your system

# Get absolute path of the current directory
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_PATH="$HOME/Library/LaunchAgents/com.autoprogrammer.launch.plist"

echo "Setting up AutoProgrammer to start automatically..."

# Create Launch Agent plist file
cat > "$PLIST_PATH" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.autoprogrammer.launch</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${APP_DIR}/launch-autoprogrammer.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/autoprogrammer.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/autoprogrammer.log</string>
</dict>
</plist>
EOL

# Load the LaunchAgent
launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH"

echo "✅ AutoProgrammer is now set to start automatically when you log in!"
echo "   You can also start it manually by running: ./launch-autoprogrammer.sh"
echo ""
echo "   Log file location: $HOME/Library/Logs/autoprogrammer.log"
echo ""
echo "   To disable autostart, run:"
echo "   launchctl unload $PLIST_PATH" 