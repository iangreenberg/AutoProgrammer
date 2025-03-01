/**
 * AI Service Client
 * Handles communication with the AI Processing Service
 */

import axios from 'axios';
import { logError } from '../middleware/logging.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Configuration
const DEFAULT_AI_SERVICE_URL = 'http://localhost:5000/process';
const AI_SERVICE_TIMEOUT = parseInt(process.env.AI_SERVICE_TIMEOUT || '30000', 10);

/**
 * Send a query to the AI Processing Service
 * @param {string} query - The user's programming query
 * @param {object} metadata - Additional metadata for the request
 * @param {object} req - The original request object (for logging)
 * @returns {Promise<object>} The AI service response
 */
export const processQuery = async (query, metadata = {}, req) => {
  try {
    // Get the AI service URL from metadata or environment variable
    const aiServiceUrl = metadata.aiServiceUrl ? 
      `${metadata.aiServiceUrl}/process` : 
      process.env.AI_SERVICE_URL || DEFAULT_AI_SERVICE_URL;
      
    console.log(`[AI-SERVICE] Sending query to AI Processing Service at ${aiServiceUrl}: ${query.substring(0, 50)}...`);
    
    const startTime = Date.now();
    
    // Prepare the request to the AI service
    const response = await axios.post(
      aiServiceUrl,
      {
        query,
        timestamp: new Date().toISOString(),
        source: 'api-gateway',
        ...metadata
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': req.id || 'unknown'
        },
        timeout: AI_SERVICE_TIMEOUT
      }
    );
    
    const processingTime = Date.now() - startTime;
    console.log(`[AI-SERVICE] Response received in ${processingTime}ms`);
    
    // Attach processing time to response
    return {
      ...response.data,
      metadata: {
        ...(response.data.metadata || {}),
        processingTime
      }
    };
  } catch (error) {
    // Log the error
    if (req) {
      logError(error, req, 'Error communicating with AI service');
    } else {
      console.error('[AI-SERVICE] Error:', error.message);
    }
    
    // Check if this is a connection error (service down)
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
      throw {
        status: 503,
        message: 'AI Processing Service is currently unavailable',
        original: error
      };
    }
    
    // Pass through any error from the AI service
    if (error.response?.data) {
      throw {
        status: error.response.status,
        message: error.response.data.error || error.message,
        original: error
      };
    }
    
    // Generic error
    throw {
      status: 500,
      message: 'Error processing request with AI service',
      original: error
    };
  }
};

/**
 * Get a fallback response when the AI service is unavailable
 * @param {string} query - The original query
 * @returns {object} A fallback response
 */
export const getFallbackResponse = (query) => {
  // Only return a mock response in development
  if (process.env.NODE_ENV === 'development') {
    return {
      success: true,
      response: `This is a fallback response for: "${query}"\n\nThe AI Processing Service is currently unavailable. This would normally connect to the AI service for processing.`,
      metadata: {
        source: 'fallback',
        processingTime: 0
      }
    };
  }
  
  // In production, just return an error
  throw {
    status: 503,
    message: 'AI Processing Service is currently unavailable'
  };
}; 