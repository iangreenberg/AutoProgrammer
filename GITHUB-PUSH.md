# Pushing AutoProgrammer to GitHub

This guide will walk you through the process of pushing your AutoProgrammer project to GitHub so others can download, use, and contribute to it.

## Prerequisites

- [Git](https://git-scm.com/) installed on your machine
- A [GitHub](https://github.com/) account
- Your AutoProgrammer project set up locally

## Step 1: Create a New Repository on GitHub

1. Log in to your GitHub account
2. Click the "+" icon in the top-right corner and select "New repository"
3. Enter "AutoProgrammer" as the repository name
4. Add a description: "A microservices-based integration solution for AutoProgrammer and Cursor"
5. Choose visibility (Public or Private)
6. Do NOT initialize with a README, .gitignore, or license (we'll push these from your local project)
7. Click "Create repository"

## Step 2: Initialize Git in Your Local Project

If your project doesn't already have Git initialized:

```bash
# Navigate to your project directory
cd /path/to/AutoProgrammer

# Initialize Git
git init
```

## Step 3: Configure Your Repository

```bash
# Add the GitHub repository as the remote origin
git remote add origin https://github.com/YOUR_USERNAME/AutoProgrammer.git

# Verify the remote was added successfully
git remote -v
```

Replace `YOUR_USERNAME` with your actual GitHub username.

## Step 4: Add Your Files and Commit

```bash
# Stage all files
git add .

# Commit the files
git commit -m "Initial commit: AutoProgrammer with Cursor integration"
```

## Step 5: Push to GitHub

```bash
# Push your code to the main branch
git push -u origin main
```

Note: If you're using an older version of Git, you might need to use `master` instead of `main`:

```bash
git push -u origin master
```

## Step 6: Verify Your Repository

1. Go to `https://github.com/YOUR_USERNAME/AutoProgrammer`
2. Ensure all your files are there
3. Check that documentation files are displaying properly

## Additional Options

### Adding GitHub Actions (Optional)

You can add GitHub Actions to automatically test your project:

1. Create a `.github/workflows` directory:
   ```bash
   mkdir -p .github/workflows
   ```

2. Create a basic workflow file:
   ```bash
   # Create a basic GitHub Actions workflow file
   cat > .github/workflows/node.js.yml << 'EOL'
   name: Node.js CI

   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]

   jobs:
     build:
       runs-on: ubuntu-latest
       strategy:
         matrix:
           node-version: [14.x, 16.x, 18.x]
       steps:
       - uses: actions/checkout@v3
       - name: Use Node.js ${{ matrix.node-version }}
         uses: actions/setup-node@v3
         with:
           node-version: ${{ matrix.node-version }}
           cache: 'npm'
       - run: npm ci
       - run: npm run build --if-present
       - run: npm test --if-present
   EOL
   ```

3. Commit and push this file:
   ```bash
   git add .github/workflows/node.js.yml
   git commit -m "Add GitHub Actions workflow"
   git push
   ```

### Publishing Releases

Once your project is ready for a release:

1. Create a tag:
   ```bash
   git tag -a v1.0.0 -m "First stable release"
   git push origin v1.0.0
   ```

2. Go to GitHub and navigate to the "Releases" section
3. Click "Draft a new release"
4. Select the tag you just pushed
5. Add release notes describing the features
6. Attach any binary files if needed
7. Publish the release

## Troubleshooting

### Authentication Issues

If you encounter authentication issues:

1. Use a personal access token:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Generate a new token with appropriate permissions
   - Use it instead of your password when pushing

2. Or set up SSH authentication:
   ```bash
   # Generate SSH key if you don't have one
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # Start the SSH agent
   eval "$(ssh-agent -s)"
   
   # Add your SSH key to the agent
   ssh-add ~/.ssh/id_ed25519
   
   # Copy the public key to add to GitHub
   cat ~/.ssh/id_ed25519.pub
   ```

   Then add this key to your GitHub account under Settings → SSH and GPG keys

   Update your remote URL to use SSH:
   ```bash
   git remote set-url origin git@github.com:YOUR_USERNAME/AutoProgrammer.git
   ```

### Large File Issues

If you have large files (>100MB) that are causing push failures:

1. Add them to `.gitignore` if they're not essential
2. Or use [Git LFS](https://git-lfs.github.com/) for large files:
   ```bash
   git lfs install
   git lfs track "*.psd" # Replace with your large file extensions
   git add .gitattributes
   ```

## Next Steps

After pushing to GitHub:

1. Update README.md links to point to your GitHub repository
2. Consider adding GitHub wiki pages for comprehensive documentation
3. Set up issue templates for bug reports and feature requests
4. Create a project board to track development 