# Free Deployment for AutoProgrammer

Here's the most efficient free way to deploy your AutoProgrammer application online with minimal configuration:

## Best Free Option: Render + Netlify Combination

### Frontend UI on Netlify (100% Free):
1. Sign up at [Netlify](https://www.netlify.com/)
2. Connect your GitHub repository
3. Configure build settings:
   - Base directory: `autoprogrammer-ui`
   - Build command: `npm install && npm run build`
   - Publish directory: `dist` (or your build output folder)
4. Add environment variable:
   - `VITE_API_URL`: (Will be your Render API Gateway URL)

### Backend Services on Render (Free Tier):

#### 1. Sign up for Render
- Create account at [Render](https://render.com/)
- Connect your GitHub repository

#### 2. Deploy API Gateway:
- Create "Web Service"
- Select your repo and set:
  - Name: `autoprogrammer-api`
  - Root Directory: `autoprogrammer-api`
  - Environment: `Node`
  - Build Command: `npm install`
  - Start Command: `npm start`
  - Plan: "Free" ($0/month)
- Add environment variables:
  ```
  NODE_ENV=production
  PORT=10000 (Render assigns its own port, but sets PORT env var)
  AI_SERVICE_URL=(Will be your AI service URL)
  FRONTEND_URLS=https://your-netlify-app.netlify.app
  RATE_LIMIT_MAX_REQUESTS=60
  RATE_LIMIT_WINDOW_MS=60000
  ```

#### 3. Deploy AI Service:
- Create another "Web Service"
- Select your repo and set:
  - Name: `autoprogrammer-ai`
  - Root Directory: `autoprogrammer-ai-service`
  - Environment: `Node`
  - Build Command: `npm install`
  - Start Command: `npm start`
  - Plan: "Free" ($0/month)
- Add environment variables:
  ```
  NODE_ENV=production
  PORT=10000 (Render assigns its own port)
  DEEPSEEK_API_KEY=your_deepseek_api_key
  DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
  DEEPSEEK_MODEL=deepseek-coder-plus
  DEEPSEEK_MAX_TOKENS=4096
  DEEPSEEK_TEMPERATURE=0.2
  GATEWAY_URL=(Your API Gateway URL)
  RATE_LIMIT_MAX_REQUESTS=30
  RATE_LIMIT_WINDOW_MS=60000
  ```

#### 4. Link Services Together:
- Once all services are deployed, copy their URLs
- Update environment variables to link them:
  - In API Gateway: Set `AI_SERVICE_URL` to AI Service URL from Render
  - In AI Service: Set `GATEWAY_URL` to API Gateway URL from Render
  - In Netlify: Set `VITE_API_URL` to API Gateway URL from Render

## Important Free Tier Limitations & Workarounds

### Render Free Tier Limitations:
- Services spin down after 15 minutes of inactivity
- This causes cold starts (30-60 second delay) when services are first accessed
- Limited to 750 hours of runtime per month
- 100 GB bandwidth per month

**Workarounds:**
1. Set up a free [UptimeRobot](https://uptimerobot.com/) monitor to ping your services every 10 minutes to prevent spin-down
2. Optimize your application to load quickly even after cold starts
3. Add loading indicators in your UI to manage user expectations during cold starts

### API Key Security:
- Render securely handles environment variables
- Your DEEPSEEK_API_KEY will be encrypted and safely stored

## Next Steps for Production

When you start getting users and need to upgrade:
1. Upgrade to Render's "Individual" plan ($7/month) to eliminate spin-downs
2. Consider Railway or DigitalOcean for better performance once you have budget

## Important CORS Configuration

For your services to communicate properly, ensure your API Gateway has CORS configured:

```javascript
app.use(cors({
  origin: process.env.FRONTEND_URLS.split(','),
  credentials: true
}));
```

This free deployment method gives you a production-ready application at zero cost until you build your user base. 