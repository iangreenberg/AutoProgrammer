#!/bin/bash

# Script to fix invisible app icon issue on macOS

echo "🤖 Starting comprehensive icon fix..."

# 1. Copy our high-contrast icon to the app bundle
echo "Copying new high-contrast robot icon to app..."
cp ./icons/icons/mac/icon.icns ~/Desktop/AutoProgrammer.app/Contents/Resources/icon.icns

# 2. Set proper icon file permissions
echo "Setting proper file permissions..."
chmod 644 ~/Desktop/AutoProgrammer.app/Contents/Resources/icon.icns

# 3. Touch the app to update modification time
echo "Updating app modification time..."
touch ~/Desktop/AutoProgrammer.app

# 4. Clear macOS icon caches
echo "Clearing system icon caches..."
sudo find /private/var/folders -name com.apple.dock.iconcache -exec rm {} \; 2>/dev/null || true
sudo find /private/var/folders -name com.apple.iconservices -exec rm -rf {} \; 2>/dev/null || true

# 5. Force reload Finder and Dock
echo "Reloading Finder and Dock..."
killall Dock
killall Finder

# 6. Set custom icon using macOS API
echo "Setting custom icon using Apple Script..."
osascript -e '
tell application "Finder"
    set file_path to POSIX file "/Users/iangreenberg/Desktop/AutoProgrammer.app" as alias
    set icon_path to POSIX file "'$(pwd)'/icons/icon.png" as alias
    set icon of file_path to icon_path
end tell
'

echo "✅ Icon fix complete! The robot icon should now be visible."
echo "If you still don't see the icon, please try restarting your Mac." 