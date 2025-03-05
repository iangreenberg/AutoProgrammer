# Deploying AutoProgrammer to Railway.app

Railway.app is ideal for microservices architectures like AutoProgrammer. It provides a simple deployment process while handling environment variables securely.

## Prerequisites
- [Railway account](https://railway.app)
- GitHub repository with your code

## Deployment Steps

### 1. Prepare Your Repository
Ensure your GitHub repository contains all three services:
- API Gateway (`autoprogrammer-api`)
- AI Service (`autoprogrammer-ai-service`) 
- Frontend UI (`autoprogrammer-ui`)

### 2. Set Up Services in Railway

#### API Gateway Service:
1. Create a new project in Railway
2. Click "Deploy from GitHub repo"
3. Select your repository
4. Navigate to "Variables" and add:
   ```
   NODE_ENV=production
   PORT=4000
   AI_SERVICE_URL=${{AI_SERVICE_URL}} (Will update after deploying AI service)
   FRONTEND_URLS=${{FRONTEND_URL}} (Will update after deploying UI)
   RATE_LIMIT_MAX_REQUESTS=60
   RATE_LIMIT_WINDOW_MS=60000
   ```
5. In "Settings", set the Root Directory to `/autoprogrammer-api`
6. Set build command: `npm install`
7. Set start command: `npm start`

#### AI Service:
1. In the same project, add a new service
2. Deploy from the same GitHub repo
3. Navigate to "Variables" and add:
   ```
   NODE_ENV=production
   PORT=5000
   DEEPSEEK_API_KEY=your_deepseek_api_key
   DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
   DEEPSEEK_MODEL=deepseek-coder-plus
   DEEPSEEK_MAX_TOKENS=4096
   DEEPSEEK_TEMPERATURE=0.2
   GATEWAY_URL=${{GATEWAY_URL}} (Will update after deployment)
   RATE_LIMIT_MAX_REQUESTS=30
   RATE_LIMIT_WINDOW_MS=60000
   ```
4. In "Settings", set the Root Directory to `/autoprogrammer-ai-service`
5. Set build command: `npm install`
6. Set start command: `npm start`

#### Frontend UI:
1. Add another service to the same project
2. Deploy from the same GitHub repo
3. Navigate to "Variables" and add:
   ```
   VITE_API_URL=${{API_URL}} (Will update after deployment)
   ```
4. In "Settings", set the Root Directory to `/autoprogrammer-ui`
5. Set build command: `npm install && npm run build`
6. Set start command: `npm run preview -- --port $PORT --host 0.0.0.0`

### 3. Link Services
After all services are deployed, you'll need to update the environment variables to link them together:

1. Get the URL for each deployed service from its "Settings" tab
2. Update the corresponding environment variables:
   - In API Gateway: Set `AI_SERVICE_URL` to AI Service URL
   - In AI Service: Set `GATEWAY_URL` to API Gateway URL
   - In Frontend UI: Set `VITE_API_URL` to API Gateway URL

### 4. Set Up Custom Domain (Optional)
1. Go to "Settings" in your Railway project
2. Navigate to "Domains"
3. Add your custom domain and follow the DNS setup instructions

## Securing Your API Key
Railway securely manages environment variables, keeping your DEEPSEEK_API_KEY protected:
- Never hardcode the API key in your codebase
- Railway will inject the key as an environment variable
- The key will not be exposed in your frontend code

## Troubleshooting
If services cannot communicate:
1. Verify all environment variables are set correctly
2. Check Railway logs for connection errors
3. Ensure CORS is properly configured in your API Gateway
4. Verify network policies in Railway aren't blocking inter-service communication 