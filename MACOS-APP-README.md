# AutoProgrammer macOS App

This project contains scripts to convert the AutoProgrammer web application into a standalone macOS application using Electron.

## Overview

The scripts in this directory will help you:

1. Set up an Electron project
2. Configure it to work with the existing AutoProgrammer services
3. Build a distributable macOS application

## Quick Start

To set up and build the macOS app in one go, run:

```bash
./setup-macos-app.sh
```

This will:
1. Create the Electron project structure
2. Install necessary dependencies
3. Create all required files
4. Set up build scripts

After running the setup script, you can:

```bash
cd autoprogrammer-desktop
npm start
```

To test the application in development mode.

## Individual Scripts

If you prefer to run the steps individually:

1. `./setup-electron.sh` - Creates the basic Electron project structure
2. `./create-main-js.sh` - Creates the main.js and preload.js files
3. `./update-package-json.sh` - Updates package.json with the correct configuration
4. `./create-build-script.sh` - Creates the build script and entitlements.plist

## Building the Application

To build the macOS application:

```bash
cd autoprogrammer-desktop
./build-macos-app.sh
```

This will:
1. Build the React UI
2. Package the Electron app
3. Create a DMG installer

The built application will be available in the `dist` directory.

## GitHub Integration

To push your project to GitHub, follow the instructions in `github-push-guide.md`.

## Notes

- The application uses the DeepSeek API with key: `sk-4556dc93bbe54e9b8ea29d0e655eb641`
- All services run locally within the Electron app
- For production use, consider implementing a more secure way to store API keys

## Troubleshooting

- If you encounter permission issues, make sure all scripts are executable with `chmod +x *.sh`
- If the build fails, check the logs in the `logs` directory
- For "App can't be opened" errors, right-click the app and select "Open" to bypass Gatekeeper 