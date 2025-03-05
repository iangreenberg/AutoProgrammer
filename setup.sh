#!/bin/bash
# AutoProgrammer Setup Script
# This script helps set up dependencies and environment for AutoProgrammer

# Print colorful messages
print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

print_red() {
    echo -e "\033[0;31m$1\033[0m"
}

# Header
print_green "===================================================="
print_green "          AutoProgrammer Setup Assistant"
print_green "===================================================="
echo

# Check for Node.js
print_yellow "Checking for Node.js..."
if command -v node > /dev/null; then
    NODE_VERSION=$(node -v)
    print_green "✓ Node.js is installed (version: $NODE_VERSION)"
else
    print_red "✗ Node.js is not installed!"
    print_yellow "Installing Node.js is recommended. Visit: https://nodejs.org/"
    print_yellow "Alternatively, you can use a package manager:"
    print_yellow "  - Mac: 'brew install node'"
    print_yellow "  - Linux: 'apt install nodejs npm' or equivalent"
    exit 1
fi

# Check for npm
print_yellow "Checking for npm..."
if command -v npm > /dev/null; then
    NPM_VERSION=$(npm -v)
    print_green "✓ npm is installed (version: $NPM_VERSION)"
else
    print_red "✗ npm is not installed!"
    print_yellow "Please install npm, which usually comes with Node.js"
    exit 1
fi

# Create env file if it doesn't exist
if [ ! -f .env ]; then
    print_yellow "Creating .env file from template..."
    cp .env.template .env
    print_green "✓ Created .env file (you may want to edit this with your specific settings)"
else
    print_yellow "Existing .env file found. Skipping creation."
fi

# Install dependencies
print_yellow "Installing dependencies (this may take a few minutes)..."
npm install
if [ $? -eq 0 ]; then
    print_green "✓ Dependencies installed successfully"
else
    print_red "✗ Error installing dependencies"
    print_yellow "Try running 'npm install' manually for more details"
    exit 1
fi

# Make integration scripts executable
print_yellow "Making integration scripts executable..."
chmod +x super-simple.sh last-resort.command
print_green "✓ Scripts are now executable"

# Create output directory
mkdir -p outputs
print_green "✓ Created outputs directory"

# Create directories for the simple integration
mkdir -p ~/.cursor-integration
print_green "✓ Created integration directory"

# Test electron installation
print_yellow "Testing Electron installation..."
if [ -f "./node_modules/.bin/electron" ]; then
    print_green "✓ Electron is installed correctly"
    
    # Add node_modules/.bin to PATH in .env
    if grep -q "PATH=" .env; then
        # Path already exists, append to it
        sed -i.bak 's|PATH=\(.*\)|PATH=\1:'"$PWD"'/node_modules/.bin|' .env
    else
        # Path doesn't exist, add it
        echo "PATH=\$PATH:$PWD/node_modules/.bin" >> .env
    fi
    
    print_green "✓ Updated PATH in .env file to include Electron"
else
    print_red "✗ Electron is not installed properly"
    print_yellow "Try running: 'npm install electron --save-dev'"
fi

# Final instructions
print_green "===================================================="
print_green "              Setup Summary"
print_green "===================================================="
print_yellow "1. Environment file: ./.env (edit as needed)"
print_yellow "2. Quick start: npm start"
print_yellow "3. For Cursor integration, use last-resort.command"
print_yellow "   (just double-click the file to run)"
print_green "===================================================="
print_green "Setup complete! You're ready to use AutoProgrammer."
print_green "====================================================" 