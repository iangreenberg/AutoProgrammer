# AutoProgrammer Microservices Troubleshooting Notes

## Architecture Overview
- **API Gateway**: Express.js service running on port 4000
- **AI Processing Service**: Express.js service running on port 5000
- **Frontend UI**: React application running on port 5174

## Issues Identified & Fixed

### DeepSeek API Configuration Issues
- Model name configuration was incorrect, causing "Model Not Exist" errors
- Resolved by updating the `.env` file in the AI Processing Service to use the correct model name
- Added a `USE_MOCK_IN_DEV=true` option to fall back to mock data during development

### API Gateway Communication
- API Gateway was timing out when trying to reach the AI Processing Service
- Both services were running but couldn't communicate properly
- Fixed by ensuring the AI Processing Service was processing requests correctly
- Added health checks before making API calls to detect service unavailability early
- Increased timeout from 30 seconds to 60 seconds for complex AI processing requests

### Node.js 19+ Compatibility
- Added `NODE_OPTIONS="--no-warnings"` to the startup script to silence fetch API experimental warnings
- This ensures a cleaner console output and prevents warnings from obscuring important messages

### Frontend Enhancements
- Added connection status indicator to the UI to show API Gateway connectivity
- Improved error handling with specific error messages for different failure scenarios
- Added retry functionality for failed connections
- Enhanced UI feedback during API request processing

### Authentication
- API key validation was correctly set up but needed to use the proper API key format
- Confirmed API key validation logic works as expected in development mode

### Port Conflicts
- Multiple instances of services were running on the same ports
- Required stopping some instances to allow proper communication
- Startup script now checks for port conflicts before starting services

## Current Status
- API Gateway is successfully running on port 4000
- AI Processing Service is successfully running on port 5000
- Direct API tests to the AI Processing Service return successful responses
- DeepSeek API integration is working correctly with fallback to mock data when needed
- Gateway-to-AI-Service communication has been stabilized with health checks and better error handling
- Frontend has visual indicators of connection status and helpful error messages

## Next Steps
- Consider containerizing the services using Docker for better isolation
- Add proper unit and integration tests
- Implement more robust logging across all services
- Consider implementing a circuit breaker pattern for better fault tolerance
- Explore performance optimizations for the AI service

## Lessons Learned
- Microservice architecture requires careful coordination of environment variables
- Timeouts between services need to be properly configured
- Error propagation between services should be handled gracefully
- Port conflicts can cause subtle issues that appear as service unavailability
- Visual feedback in the UI about service status greatly improves debugging experience
- Fallback mechanisms (like mock data) are essential for development work 