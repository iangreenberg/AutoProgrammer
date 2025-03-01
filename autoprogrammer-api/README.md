# AutoProgrammer API Gateway

This is the API Gateway microservice for the AutoProgrammer application. It serves as a central hub for the microservices architecture, handling communication between the frontend UI and the AI Processing Service.

## Features

- **Proxy for AI Processing Service**: Forwards requests from the frontend to the AI service at `localhost:5000/process`
- **Authentication**: API key validation for secure access
- **Logging**: Comprehensive request and error logging
- **Error Handling**: Consistent error responses and fallbacks
- **CORS Support**: Configured for development with React/Vite frontend

## Architecture

This application follows a microservices architecture:

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│   Frontend UI   │─────▶│   API Gateway   │─────▶│  AI Processing  │
│  (React/Vite)   │      │   (Express.js)  │      │    Service      │
│                 │◀─────│                 │◀─────│                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
   localhost:5174          localhost:4000           localhost:5000
```

## Setup and Installation

1. Install dependencies:
   ```
   npm install
   ```

2. Start the development server:
   ```
   npm run dev
   ```

3. For production:
   ```
   npm start
   ```

## API Endpoints

### Health Check
```
GET /health
```

Returns the current status of the API Gateway service.

### Service Information
```
GET /
```

Returns information about the API Gateway service and available endpoints.

### Submit Query
```
POST /ask
```

Submit a programming query to be processed by the AI service.

#### Request Format:
```json
{
  "query": "Your programming question or request"
}
```

#### Headers:
- For production: `X-API-Key`: Your API key
- Content-Type: application/json

#### Response Format:
```json
{
  "success": true,
  "response": "AI-generated response to the query",
  "metadata": {
    "processingTime": 1234,
    "source": "ai-service"
  }
}
```

## Environment Variables

- `PORT`: Port to run the server (default: 4000)
- `NODE_ENV`: Environment (development, production)
- `API_KEY`: API key for authentication in production
- `AI_SERVICE_URL`: URL of the AI Processing Service (default: http://localhost:5000/process)
- `AI_SERVICE_TIMEOUT`: Timeout for AI service requests in ms (default: 30000)

## Development Mode

In development mode (`NODE_ENV=development`):
- API key validation is disabled
- Detailed error messages are provided
- Fallback responses are given when the AI service is unavailable

## Folder Structure

```
├── gateway.js               # Main entry point
├── middleware/              # Middleware components
│   ├── auth.js              # Authentication middleware
│   ├── error-handler.js     # Error handling middleware
│   ├── logging.js           # Logging middleware
│   └── validation.js        # Request validation
├── services/                # Service clients
│   └── ai-service.js        # AI Processing Service client
└── logs/                    # Generated log files
    ├── access.log           # Access logs
    └── error.log            # Error logs
```

## Error Handling

The API Gateway provides consistent error responses in the following format:

```json
{
  "success": false,
  "error": "Error type",
  "message": "Detailed error message"
}
```

Common error types:
- 400: Bad Request
- 401: Unauthorized
- 404: Not Found
- 500: Internal Server Error
- 503: Service Unavailable (AI service down) 