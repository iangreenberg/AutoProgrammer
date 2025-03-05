# AutoProgrammer Installation Guide

This guide will help you set up AutoProgrammer with Cursor integration, providing different options based on your needs and technical comfort level.

## Quick Setup (Recommended)

The easiest way to get started is to run our setup script:

```bash
# Make the script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

This script will:
- Check for Node.js and npm
- Create an environment file from the template
- Install dependencies (including Electron)
- Make integration scripts executable
- Provide final instructions

## Installation Options

### Option 1: Standard Installation

1. Ensure you have Node.js installed (version 14 or higher)
2. Clone or download this repository
3. Run the setup script as described above
4. Start the application with `npm start`

### Option 2: Docker-based Installation

For a containerized installation that separates components into microservices:

```bash
# Build the Docker images
npm run docker:build

# Start the containers
npm run docker:start
```

This will start three microservices:
- Main application
- Output processing service
- Cursor integration service

### Option 3: Minimal Installation (No Dependencies)

If you're having trouble with the full installation, you can use our minimal approach:

1. Simply double-click the `last-resort.command` file in Finder
2. Keep the terminal window open while using AutoProgrammer

This option requires no dependencies or installation and will actively monitor for output files.

## Environment Configuration

The `.env.template` file contains common configuration options. Copy this to `.env` and modify as needed:

```bash
cp .env.template .env
```

Key settings include:
- `NODE_PATH`: Path to your Node.js installation
- `ELECTRON_PATH`: Path to Electron
- `OUTPUT_DIR`: Directory where generated files are saved
- `ENABLE_CURSOR_INTEGRATION`: Set to true to enable integration

## Troubleshooting

### "electron: command not found" Error

This indicates Electron is not installed or not in your PATH. Solutions:

1. Run the setup script: `./setup.sh`
2. Install Electron manually: `npm install electron --save-dev`
3. Use the minimal approach with `last-resort.command`

### Output Not Being Detected

If outputs aren't being detected:

1. Check that the terminal window is open and running
2. Try the minimal approach with `last-resort.command`
3. Edit a test file (test-output.txt) to see if changes are detected

## System Requirements

- macOS (preferred), Linux, or Windows
- Node.js version 14 or higher (for full installation)
- 100MB disk space for the application
- No special requirements for minimal installation

## Next Steps

After installation, proceed to the README for usage instructions and features. 