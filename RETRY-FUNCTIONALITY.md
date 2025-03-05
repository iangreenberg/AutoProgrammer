# AutoProgrammer - Automatic Retry Functionality

This document explains the automatic retry functionality implemented in AutoProgrammer to handle timeout errors when communicating with the AI service.

## Overview

When the AI service takes too long to respond (timeout), AutoProgrammer now automatically retries the request instead of immediately showing an error message. This improves the user experience by increasing the chances of getting a successful response for complex queries.

## How It Works

The retry functionality is implemented at multiple levels:

### 1. UI Layer (React Frontend)

- When a timeout occurs, the UI automatically retries the request up to 3 times
- The user is informed that a retry is in progress with a message like "Automatically retrying (1/3)..."
- The retry button shows the current retry attempt
- Each retry uses a longer timeout to give the AI service more time to respond

### 2. API Gateway Layer

- The API Gateway increases the timeout for retry attempts
- It implements its own retry logic (up to 2 retries) for communication with the AI service
- In development mode, it provides fallback responses if all retries fail

### 3. Error Handling

- Improved error messages provide better information about timeouts
- The system distinguishes between different types of errors (timeout vs. connection errors)
- In development mode, fallback responses are provided even after retries fail

## Configuration

The retry behavior can be configured through environment variables:

```
# In .env file for API Gateway
AI_SERVICE_TIMEOUT=120000       # Base timeout in milliseconds (2 minutes)
MAX_RETRY_ATTEMPTS=2            # Number of retry attempts
RETRY_DELAY=3000                # Delay between retries in milliseconds
```

## Testing the Retry Functionality

A test script is provided to simulate a timeout and test the retry mechanism:

```bash
./test-retry.sh
```

This script sends a complex query that is likely to trigger a timeout, allowing you to observe the retry behavior in action.

## Logs

When a retry occurs, you'll see messages in the logs:

- UI: "Automatically retrying (1/3)..."
- API Gateway: "[AI-SERVICE] Retry attempt 1/2: Sending query to AI Processing Service..."
- API Gateway: "Request timed out. Retrying (1/2)..."

## Fallback Responses

If all retry attempts fail:

- In development mode: A fallback response is provided
- In production: An error message is shown to the user

## Benefits

- Improved reliability for complex queries
- Better user experience with informative progress updates
- Higher success rate for AI responses
- Graceful degradation when the AI service is under heavy load 