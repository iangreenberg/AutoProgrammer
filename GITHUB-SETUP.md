# Setting Up AutoProgrammer from GitHub

This guide walks you through setting up AutoProgrammer after downloading or cloning it from GitHub.

## Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/yourusername/AutoProgrammer.git

# Navigate into the project directory
cd AutoProgrammer
```

## Step 2: Choose Your Setup Method

### Option A: Quick Setup (Recommended)

The easiest way to get started is using our automatic setup script:

```bash
# Make the script executable (macOS/Linux)
chmod +x setup.sh

# Run the setup script
./setup.sh
```

This script will:
- Check if you have Node.js and npm installed
- Install dependencies (including Electron)
- Create the necessary environment file
- Make all integration scripts executable
- Set up the proper directory structure

### Option B: Minimal Setup (No Dependencies)

If you're having trouble with Node.js or just want the simplest solution:

```bash
# Make the script executable (macOS/Linux)
chmod +x last-resort.command

# Simply run this file
./last-resort.command

# Or double-click it in Finder (macOS)
```

This minimal approach requires no dependencies and will work on any Mac.

### Option C: Docker Setup (For Microservices)

For a containerized setup with separate microservices:

```bash
# Build the Docker images
npm run docker:build

# Start the containers
npm run docker:start
```

## Step 3: Verify Your Installation

To verify everything is working:

1. **Edit the test file**:
   ```bash
   echo "Test content $(date)" >> test-output.txt
   ```

2. **Check if the output appears**:
   - If you're using the basic setup, you should see the content appear in the terminal
   - If you're using the full app, you should see it in the application window

## Platform-Specific Instructions

### macOS

1. You may need to allow running the scripts:
   - Right-click the script (last-resort.command or setup.sh)
   - Select "Open" from the context menu
   - Click "Open" when prompted

2. If using the Docker option, ensure Docker Desktop is installed and running

### Windows

1. For the minimal setup, use `super-simple.sh` with Git Bash or WSL
2. For the full setup, run:
   ```
   npm install
   npm start
   ```

### Linux

1. Ensure Node.js and npm are installed for your distribution
2. Make scripts executable:
   ```
   chmod +x *.sh
   ```

## Troubleshooting Common Issues

### "electron: command not found"

This means Electron is not installed or not in your PATH:

1. Run the setup script: `./setup.sh`
2. Or install Electron manually: `npm install electron --save-dev`
3. Or use the minimal approach with `last-resort.command`

### Scripts Not Running

If scripts won't run:

```bash
# Ensure they are executable
chmod +x *.sh *.command

# Try running with bash explicitly
bash last-resort.command
```

### Outputs Not Being Detected

1. Check that the terminal window is open and running
2. Try editing test-output.txt to see if changes are detected
3. Try running the minimal script: `./super-simple.sh`

## Next Steps

1. Start the full application with: `npm start`
2. When prompted to access files by Cursor, allow access
3. Try the test output to verify integration is working
4. If successful, you're ready to use AutoProgrammer with Cursor! 