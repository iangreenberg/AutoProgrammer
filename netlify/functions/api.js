// Simplified API Gateway for Netlify Functions
const axios = require('axios');

exports.handler = async function(event, context) {
  // Set CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
  };
  
  // Handle preflight OPTIONS request
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    };
  }
  
  try {
    // Route the request to the AI service
    if (event.path.startsWith('/.netlify/functions/api/health')) {
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ status: 'healthy', message: 'API Gateway is operational' })
      };
    }
    
    // Forward request to AI service function
    const aiServiceUrl = '/.netlify/functions/ai';
    const requestPath = event.path.replace('/.netlify/functions/api', '');
    
    // Call the AI service function directly
    const response = await axios({
      method: event.httpMethod,
      url: `${process.env.URL}${aiServiceUrl}${requestPath}`,
      headers: event.headers,
      data: event.body ? JSON.parse(event.body) : {}
    });
    
    return {
      statusCode: response.status,
      headers,
      body: JSON.stringify(response.data)
    };
  } catch (error) {
    console.error('API Gateway Error:', error);
    
    return {
      statusCode: error.response?.status || 500,
      headers,
      body: JSON.stringify({
        error: 'Failed to process request',
        message: error.message
      })
    };
  }
}; 