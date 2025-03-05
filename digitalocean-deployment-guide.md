# Deploying AutoProgrammer to DigitalOcean App Platform

DigitalOcean App Platform provides a fully-managed PaaS solution ideal for microservices architectures like AutoProgrammer.

## Prerequisites
- [DigitalOcean account](https://www.digitalocean.com/)
- GitHub repository with your code

## Deployment Steps

### 1. Prepare Your Repository
Ensure your GitHub repository is organized with the three services:
- API Gateway (`autoprogrammer-api`)
- AI Service (`autoprogrammer-ai-service`) 
- Frontend UI (`autoprogrammer-ui`)

### 2. Create a New App on DigitalOcean

1. Log in to your DigitalOcean account
2. Go to the App Platform section
3. Click "Create App"
4. Select GitHub as your source
5. Authorize DigitalOcean to access your repositories
6. Select your AutoProgrammer repository

### 3. Configure Components

You'll need to set up each service as a separate component:

#### Frontend UI Component:
1. Select the `/autoprogrammer-ui` directory
2. Set as a "Web Service"
3. Choose the "React.js" build preset
4. Configure:
   - Build Command: `npm install && npm run build`
   - Run Command: `npm run preview -- --port $PORT --host 0.0.0.0`
   - HTTP Port: 80
5. Add environment variable:
   - `VITE_API_URL`: (leave empty for now, will update after API Gateway is deployed)

#### API Gateway Component:
1. Click "Add Component" and select "Service" 
2. Select the `/autoprogrammer-api` directory
3. Set as a "Web Service"
4. Choose "Node.js" as the build preset
5. Configure:
   - Build Command: `npm install`
   - Run Command: `npm start`
   - HTTP Port: 4000
6. Add environment variables:
   ```
   NODE_ENV=production
   PORT=4000
   AI_SERVICE_URL= (leave empty for now)
   FRONTEND_URLS= (will be the URL of your UI component)
   RATE_LIMIT_MAX_REQUESTS=60
   RATE_LIMIT_WINDOW_MS=60000
   ```

#### AI Service Component:
1. Click "Add Component" again
2. Select the `/autoprogrammer-ai-service` directory
3. Set as a "Web Service"
4. Choose "Node.js" as the build preset
5. Configure:
   - Build Command: `npm install`
   - Run Command: `npm start`
   - HTTP Port: 5000
6. Add environment variables:
   ```
   NODE_ENV=production
   PORT=5000
   DEEPSEEK_API_KEY=your_deepseek_api_key
   DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
   DEEPSEEK_MODEL=deepseek-coder-plus
   DEEPSEEK_MAX_TOKENS=4096
   DEEPSEEK_TEMPERATURE=0.2
   GATEWAY_URL= (leave empty for now)
   RATE_LIMIT_MAX_REQUESTS=30
   RATE_LIMIT_WINDOW_MS=60000
   ```

### 4. Link Services

After initial deployment:

1. Go to the "Components" tab of your app
2. For each component, copy its URL
3. Update the environment variables to link services:
   - In API Gateway: Set `AI_SERVICE_URL` to AI Service URL
   - In AI Service: Set `GATEWAY_URL` to API Gateway URL
   - In Frontend UI: Set `VITE_API_URL` to API Gateway URL
4. These changes will trigger a redeployment

### 5. Set Up Custom Domain (Optional)

1. Go to the "Settings" tab of your app
2. Click "Domains" and "Add Domain"
3. Follow the instructions to configure your domain's DNS settings

## Secure API Key Management

1. In DigitalOcean App Platform, environment variables are securely stored
2. For additional security, mark the `DEEPSEEK_API_KEY` as an "Encrypted" variable
3. DigitalOcean will never expose this key in logs or to unauthorized users

## Cost Optimization

DigitalOcean App Platform pricing is based on resources used:
- Consider starting with Basic tier for each component
- You can scale up specific components as needed
- Development environments can be configured to automatically sleep during periods of inactivity

## Monitoring and Troubleshooting

1. Access logs for each component from the app's "Components" tab
2. Set up alerts for service health and performance
3. Use DigitalOcean's built-in metrics to monitor resource usage and optimize costs
4. CORS issues can be debugged using the DigitalOcean console 