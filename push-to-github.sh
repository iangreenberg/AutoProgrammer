#!/bin/bash

# AutoProgrammer Desktop - GitHub Push Script
# This script helps push the AutoProgrammer Desktop app to GitHub

echo "🚀 Preparing to push AutoProgrammer Desktop to GitHub..."

# Check if user provided a GitHub repository URL or we should create a new one
if [ -z "$1" ]; then
  echo "📝 No GitHub repository URL provided."
  read -p "Do you want to create a new GitHub repository? (y/n): " create_new
  
  if [ "$create_new" = "y" ]; then
    read -p "Enter your GitHub username: " github_username
    read -p "Enter repository name [autoprogrammer-desktop]: " repo_name
    repo_name=${repo_name:-autoprogrammer-desktop}
    
    echo "🌟 Creating new GitHub repository: $github_username/$repo_name"
    gh repo create "$github_username/$repo_name" --public --confirm || {
      echo "❌ Failed to create GitHub repository. Make sure 'gh' CLI is installed."
      echo "   Install with: 'brew install gh' and then authenticate with 'gh auth login'"
      exit 1
    }
    
    REPO_URL="https://github.com/$github_username/$repo_name.git"
  else
    read -p "Enter your GitHub repository URL: " REPO_URL
  fi
else
  REPO_URL="$1"
fi

# Validate repository URL
if [ -z "$REPO_URL" ]; then
  echo "❌ No GitHub repository URL provided. Exiting."
  exit 1
fi

# Check if .git directory exists
if [ ! -d ".git" ]; then
  echo "🔧 Initializing Git repository..."
  git init
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
  echo "📄 Creating .gitignore file..."
  cat > .gitignore << EOF
# Node modules
node_modules/

# Build artifacts
dist/

# Environment files
.env
.env.local

# macOS specific files
.DS_Store
.AppleDouble
.LSOverride

# Logs
logs/
*.log
npm-debug.log*

# Editor directories and files
.idea/
.vscode/
*.swp
*.swo
EOF
fi

# Add remote if needed
if ! git remote | grep -q "origin"; then
  echo "🔄 Adding remote origin: $REPO_URL"
  git remote add origin "$REPO_URL"
else
  echo "🔄 Updating remote origin to: $REPO_URL"
  git remote set-url origin "$REPO_URL"
fi

# Add all files except those in .gitignore
echo "📦 Adding files to Git..."
git add .

# Commit changes
echo "💾 Committing changes..."
read -p "Enter commit message [Update AutoProgrammer Desktop app]: " commit_message
commit_message=${commit_message:-"Update AutoProgrammer Desktop app"}
git commit -m "$commit_message"

# Push to GitHub
echo "☁️ Pushing to GitHub..."
git push -u origin main

echo "✅ AutoProgrammer Desktop has been pushed to GitHub: $REPO_URL"
echo "🌐 View your repository at: ${REPO_URL%.git}" 