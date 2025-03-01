# AutoProgrammer Microservices

A microservice-based architecture for generating programming solutions using AI.

## Architecture Overview

The project consists of the following microservices:

### 1. API Gateway (Port 4000)

The central entry point for all requests. Handles authentication, request validation, and routes requests to the appropriate service.

- **Technologies**: Node.js, Express.js
- **Features**: Authentication, rate limiting, request validation, logging

### 2. AI Processing Service (Port 5000)

Handles all AI-related processing using the DeepSeek API to generate programming solutions.

- **Technologies**: Node.js, Express.js, DeepSeek API
- **Features**: AI query processing, response formatting, error handling

### 3. Frontend UI (Port 5174)

User interface for interacting with the AutoProgrammer system.

- **Technologies**: React, Vite
- **Features**: User-friendly interface for submitting programming queries

## Getting Started

### Prerequisites

- Node.js v16+
- npm or yarn

### Installation

1. Clone this repository
2. Set up environment variables (see `.env.example` in each directory)
3. Install dependencies for each microservice

```bash
# For the API Gateway
cd autoprogrammer-api
npm install

# For the AI Processing Service
cd ../autoprogrammer-ai-service
npm install

# For the Frontend (if included)
cd ../autoprogrammer-ui
npm install
```

### Running the Services

Run each service in development mode:

```bash
# Start the API Gateway
cd autoprogrammer-api
npm run dev

# Start the AI Processing Service
cd ../autoprogrammer-ai-service
npm run dev

# Start the Frontend (if included)
cd ../autoprogrammer-ui
npm run dev
```

Or use the provided startup script:

```bash
./startup.sh
```

## API Documentation

### Main Endpoint

`POST /ask` - Submit a programming query

#### Request Body

```json
{
  "query": "Create a simple REST API with Node.js"
}
```

#### Response

```json
{
  "success": true,
  "response": "Detailed programming solution...",
  "metadata": {
    "processingTime": 1234,
    "source": "deepseek-r1"
  }
}
```

## License

MIT

## Troubleshooting

See [troubleshooting-notes.md](troubleshooting-notes.md) for common issues and solutions. 