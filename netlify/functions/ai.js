// Simplified AI Service for Netlify Functions
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
    // Health check endpoint
    if (event.path.startsWith('/.netlify/functions/ai/health')) {
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ status: 'healthy', message: 'AI Service is operational' })
      };
    }
    
    // Process code generation request
    if (event.path.startsWith('/.netlify/functions/ai/generate') && event.httpMethod === 'POST') {
      const requestBody = JSON.parse(event.body);
      const { prompt, language, complexity } = requestBody;
      
      // Call DeepSeek API
      const apiResponse = await axios({
        method: 'POST',
        url: 'https://api.deepseek.com/v1/chat/completions',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`
        },
        data: {
          model: process.env.DEEPSEEK_MODEL || "deepseek-coder-plus",
          messages: [
            {
              role: "system",
              content: `You are an expert programmer. Generate high-quality, well-documented ${language} code based on the user's requirements. Keep your response focused on code.`
            },
            {
              role: "user",
              content: prompt
            }
          ],
          max_tokens: parseInt(process.env.DEEPSEEK_MAX_TOKENS) || 4096,
          temperature: parseFloat(process.env.DEEPSEEK_TEMPERATURE) || 0.2
        }
      });
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          code: apiResponse.data.choices[0].message.content,
          language: language,
          model: apiResponse.data.model
        })
      };
    }
    
    // Fallback for unhandled routes
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Route not found' })
    };
    
  } catch (error) {
    console.error('AI Service Error:', error);
    
    return {
      statusCode: error.response?.status || 500,
      headers,
      body: JSON.stringify({
        error: 'Failed to process AI request',
        message: error.message
      })
    };
  }
}; 