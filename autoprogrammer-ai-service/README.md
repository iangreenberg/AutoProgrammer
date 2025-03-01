# AutoProgrammer AI Processing Service

This microservice processes software development queries by leveraging the DeepSeek R1 API and formatting responses into structured development strategies. It acts as the AI processing backend for the AutoProgrammer system.

## Features

- **DeepSeek R1 API Integration**: Securely calls the DeepSeek API to generate high-quality responses
- **Response Formatting**: Structures responses into software architecture, best practices, and implementation strategies
- **Cursor-Optimized Prompts**: Generates prompts optimized for AI coding assistants
- **Development Mode**: Provides mock responses when no API key is available

## Architecture

The AI Processing Service is part of the AutoProgrammer microservices architecture:

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

1. **Clone the repository**

2. **Install dependencies**:
   ```
   npm install
   ```

3. **Configure environment variables**:
   - Copy `.env.example` to `.env`
   - Add your DeepSeek API key to `DEEPSEEK_API_KEY`
   ```
   cp .env.example .env
   ```

4. **Start the development server**:
   ```
   npm run dev
   ```
   
5. **For production**:
   ```
   NODE_ENV=production npm start
   ```

## API Endpoints

### Health Check
```
GET /health
```
Returns the current status of the AI Processing Service.

### Process Query
```
POST /process
```
Processes a software development query and returns a structured response.

#### Request Format:
```json
{
  "query": "Your software development question or request"
}
```

#### Response Format:
```json
{
  "success": true,
  "response": "Formatted, structured response with software architecture, best practices, etc.",
  "metadata": {
    "requestId": "unique-request-id",
    "processingTime": 1234,
    "source": "deepseek-r1"
  }
}
```

## Environment Variables

- `PORT`: Port to run the server (default: 5000)
- `NODE_ENV`: Environment (development, production)
- `DEEPSEEK_API_KEY`: Your DeepSeek API key (required for production)
- `DEEPSEEK_API_URL`: DeepSeek API endpoint
- `DEEPSEEK_MODEL`: Model to use (default: deepseek-coder-plus)
- `DEEPSEEK_MAX_TOKENS`: Maximum tokens to generate (default: 4096)
- `DEEPSEEK_TEMPERATURE`: Model temperature (default: 0.2)

## Development Mode

In development mode (`NODE_ENV=development`):
- If `DEEPSEEK_API_KEY` is not set, mock responses will be provided
- Detailed error messages are shown
- More verbose logging is enabled

## Folder Structure

```
├── server.js                # Main entry point
├── services/                # Service modules
│   └── deepseek-service.js  # DeepSeek API integration
├── utils/                   # Utility functions
│   └── formatter.js         # Response formatting utility
└── logs/                    # Generated log files
```

## Error Handling

The service provides consistent error responses with appropriate HTTP status codes:

- 400: Bad Request (invalid input)
- 500: Internal Server Error (server-side issues)
- 503: Service Unavailable (DeepSeek API unavailable)

## Extending the Service

To extend with additional AI providers:
1. Create a new service file in the `services/` directory
2. Implement the API integration
3. Update server.js to use the new service 