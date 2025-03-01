/**
 * DeepSeek R1 API Integration Service
 * Handles communication with the DeepSeek API
 */

import axios from 'axios';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// DeepSeek API configuration
const DEEPSEEK_API_URL = process.env.DEEPSEEK_API_URL || 'https://api.deepseek.com/v1/chat/completions';
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;
const DEEPSEEK_MODEL = process.env.DEEPSEEK_MODEL || 'deepseek-coder-plus';
const DEEPSEEK_MAX_TOKENS = parseInt(process.env.DEEPSEEK_MAX_TOKENS || '4096', 10);
const DEEPSEEK_TEMPERATURE = parseFloat(process.env.DEEPSEEK_TEMPERATURE || '0.2');

/**
 * Processes a query using the DeepSeek API
 * @param {string} query - The software development query
 * @param {string} requestId - Request ID for tracking
 * @returns {Promise<string>} - The DeepSeek API response
 */
export async function processWithDeepSeek(query, requestId) {
  // If in development mode and no API key, return a mock response
  if (process.env.NODE_ENV === 'development' && !DEEPSEEK_API_KEY) {
    console.log(`[${requestId}] Using mock response in development mode`);
    return getMockResponse(query);
  }
  
  try {
    console.log(`[${requestId}] Sending request to DeepSeek API`);
    
    // Craft the prompt
    const messages = [
      {
        role: 'system',
        content: `You are an expert software architect and developer. 
Your task is to analyze programming requests and provide detailed, structured responses with:
1. Software Architecture - Break down the technical approach into components, patterns, and technologies
2. Best Practices - Outline coding standards, security considerations, and optimization tips
3. Implementation Strategy - Provide a clear step-by-step approach to building the solution
4. Cursor-Optimized Prompts - Provide specific prompts that can be used with AI coding assistants

Your responses should be well-organized, include code examples where appropriate, and focus on practical, maintainable solutions.`
      },
      {
        role: 'user',
        content: query
      }
    ];
    
    // Call DeepSeek API
    const response = await axios.post(
      DEEPSEEK_API_URL,
      {
        model: DEEPSEEK_MODEL,
        messages,
        max_tokens: DEEPSEEK_MAX_TOKENS,
        temperature: DEEPSEEK_TEMPERATURE
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${DEEPSEEK_API_KEY}`,
          'X-Request-ID': requestId
        },
        timeout: 60000 // 60-second timeout
      }
    );
    
    // Extract and return the content
    const content = response.data.choices[0].message.content;
    console.log(`[${requestId}] DeepSeek API response received (${content.length} chars)`);
    
    return content;
  } catch (error) {
    console.error(`[${requestId}] DeepSeek API Error:`, error.message);
    
    // Format error for better handling
    const formattedError = {
      status: error.response?.status || 500,
      type: 'DeepSeek API Error',
      message: error.response?.data?.error?.message || error.message,
      stack: error.stack
    };
    
    // Additional logging for API-specific errors
    if (error.response?.data) {
      console.error(`[${requestId}] DeepSeek API Error Details:`, JSON.stringify(error.response.data, null, 2));
    }
    
    throw formattedError;
  }
}

/**
 * Generate a mock response for development mode without API key
 * @param {string} query - The original query
 * @returns {string} - A formatted mock response
 */
function getMockResponse(query) {
  return `# Software Development Strategy for: ${query}

## 1. Software Architecture

### Components
- **Frontend**: React.js with TypeScript for type safety
- **Backend**: Node.js Express server with modular architecture
- **Database**: MongoDB for flexible document storage
- **API Layer**: RESTful API with proper versioning

### Design Patterns
- Repository pattern for data access
- Facade pattern for service interfaces
- Observer pattern for event handling

## 2. Best Practices

### Coding Standards
- Follow Airbnb JavaScript Style Guide
- Implement comprehensive unit testing (>80% coverage)
- Use ESLint and Prettier for code quality

### Security Considerations
- Implement JWT authentication
- Use HTTPS for all communications
- Sanitize all user inputs
- Implement rate limiting

### Performance Optimization
- Use React.memo for component optimization
- Implement database indexing
- Cache frequent queries
- Use compression middleware

## 3. Implementation Strategy

1. **Setup Project Structure**
   - Initialize frontend and backend repositories
   - Configure TypeScript and ESLint
   - Set up CI/CD pipeline

2. **Develop Core Features**
   - Create user authentication system
   - Implement database models
   - Develop API endpoints
   - Build frontend components

3. **Testing and Quality Assurance**
   - Write unit and integration tests
   - Perform security audit
   - Optimize performance
   - Conduct user acceptance testing

## 4. Cursor-Optimized Prompts

### For Frontend Development
- "Create a React component for user authentication with form validation"
- "Implement a responsive dashboard that displays user statistics"
- "Design a notification system that shows real-time updates"

### For Backend Development
- "Write a Node.js middleware for JWT authentication"
- "Create Express routes for user CRUD operations"
- "Implement MongoDB schema for user profiles with validation"

### For Testing
- "Generate unit tests for the authentication service using Jest"
- "Create integration tests for the API endpoints"

This is a development-mode mock response. In production, this would be generated by the DeepSeek API.`;
} 