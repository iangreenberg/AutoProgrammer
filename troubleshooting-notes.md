# AutoProgrammer Microservices Troubleshooting Notes

## Architecture Overview
- **API Gateway**: Express.js service running on port 4000
- **AI Processing Service**: Express.js service running on port 5000
- **Frontend UI**: React application running on port 5174

## Issues Identified & Fixed

### DeepSeek API Configuration Issues
- Model name configuration was incorrect, causing "Model Not Exist" errors
- Resolved by updating the `.env` file in the AI Processing Service to use the correct model name

### API Gateway Communication
- API Gateway was timing out when trying to reach the AI Processing Service
- Both services were running but couldn't communicate properly
- Fixed by ensuring the AI Processing Service was processing requests correctly

### Authentication
- API key validation was correctly set up but needed to use the proper API key format
- Confirmed API key validation logic works as expected in development mode

### Port Conflicts
- Multiple instances of services were running on the same ports
- Required stopping some instances to allow proper communication

## Current Status
- API Gateway is successfully running on port 4000
- AI Processing Service is successfully running on port 5000
- Direct API tests to the AI Processing Service return successful responses
- DeepSeek API integration is working correctly
- Gateway-to-AI-Service communication still has some instability but works when both services are properly configured

## Next Steps
- Consider adding more robust error handling in the API Gateway
- Improve timeout handling between microservices
- Add more comprehensive logging to trace request flows
- Monitor DeepSeek API usage and response times
- Add proper unit and integration tests

## Lessons Learned
- Microservice architecture requires careful coordination of environment variables
- Timeouts between services need to be properly configured
- Error propagation between services should be handled gracefully
- Port conflicts can cause subtle issues that appear as service unavailability 