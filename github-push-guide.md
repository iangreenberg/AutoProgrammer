# Pushing AutoProgrammer Desktop to GitHub

This guide will walk you through the process of pushing your AutoProgrammer Desktop application to GitHub.

## Prerequisites

- Git installed on your system
- GitHub account
- AutoProgrammer Desktop app code ready

## Step 1: Initialize Git Repository

Navigate to your AutoProgrammer Desktop directory and initialize a Git repository:

```bash
cd ~/Desktop/AutoProgrammer/autoprogrammer-desktop
git init
```

## Step 2: Create .gitignore File

Create a `.gitignore` file to exclude unnecessary files from your repository:

```bash
cat > .gitignore << 'EOL'
# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
package-lock.json
yarn.lock

# Electron
dist/
out/

# Logs
logs/
*.log

# Mac OS
.DS_Store

# IDE files
.idea/
.vscode/
*.swp
*.swo
EOL
```

## Step 3: Add Files to Git

Add your files to the Git staging area:

```bash
git add .gitignore README.md main.js preload.js package.json build-macos-app.sh entitlements.plist MACOS-APP-GUIDE.md
```

## Step 4: Commit Changes

Commit your changes with a descriptive message:

```bash
git commit -m "Initial commit for AutoProgrammer Desktop"
```

## Step 5: Create GitHub Repository

1. Go to [GitHub](https://github.com/) and sign in to your account
2. Click on the "+" icon in the top-right corner and select "New repository"
3. Name your repository (e.g., "autoprogrammer-desktop")
4. Add a description (optional)
5. Choose whether to make it public or private
6. Do not initialize the repository with a README, .gitignore, or license
7. Click "Create repository"

## Step 6: Connect Local Repository to GitHub

After creating the repository, GitHub will display commands to push an existing repository. Use the commands shown:

```bash
git remote add origin https://github.com/YOUR_USERNAME/autoprogrammer-desktop.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

## Step 7: Verify

Visit your GitHub repository URL to verify that your files have been pushed successfully.

## Additional Tips

- If you make changes to your code, you can push them to GitHub using:
  ```bash
  git add .
  git commit -m "Description of changes"
  git push
  ```

- Consider adding a license file to specify how others can use your code
- Update your README.md with detailed information about your project
- Consider setting up GitHub Actions for continuous integration/deployment 