# Easy Netlify Deployment Guide

This guide will help you deploy your AutoProgrammer to Netlify in just a few clicks. No complicated setup required!

## Step 1: Push Your Code to GitHub

Make sure all these files are pushed to your GitHub repository:
- The `netlify.toml` file in the root directory
- The `netlify/functions` folder with the API functions
- Your existing UI code

## Step 2: Deploy on Netlify

1. **Go to Netlify**: Visit https://app.netlify.com/
2. **Connect Repository**:
   - Click "Add new site" → "Import an existing project"
   - Select your GitHub repository
   - Netlify will automatically detect the `netlify.toml` configuration

3. **Add Your DeepSeek API Key**:
   - After deployment starts, go to "Site settings" → "Environment variables"
   - Add a new variable:
     - Key: `DEEPSEEK_API_KEY`
     - Value: `your_api_key_here` (replace with your actual DeepSeek API key)
   - Click "Save"

4. **Optional Configuration**:
   You can also add these optional environment variables:
   - `DEEPSEEK_MODEL`: Default is "deepseek-coder-plus"
   - `DEEPSEEK_MAX_TOKENS`: Default is 4096
   - `DEEPSEEK_TEMPERATURE`: Default is 0.2

5. **Trigger a New Deployment**:
   - Go to "Deploys" tab
   - Click "Trigger deploy" → "Deploy site"

## Step 3: Access Your Live Site

Once the deployment is complete:
1. Click on the URL provided by Netlify (looks like `https://your-site-name.netlify.app`)
2. Your AutoProgrammer should be up and running!

## Troubleshooting

If you encounter any issues:

1. **Check Function Logs**:
   - Go to Netlify dashboard → "Functions" tab
   - Click on a function to see its logs

2. **Verify API Key**:
   - Make sure your DEEPSEEK_API_KEY is correctly set in environment variables
   - The key should not have any extra spaces

3. **Check CORS Issues**:
   - If you see CORS errors in the browser console, ensure your frontend is making requests to `/api` and not an absolute URL

4. **Redeploy if Needed**:
   - Sometimes a fresh deploy fixes issues
   - Go to "Deploys" tab and click "Trigger deploy" 