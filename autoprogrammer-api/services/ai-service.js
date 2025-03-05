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
// Increase default timeout to 2 minutes
const AI_SERVICE_TIMEOUT = parseInt(process.env.AI_SERVICE_TIMEOUT || '120000', 10); // Increased to 120 seconds
// Number of retry attempts for timeout errors
const MAX_RETRY_ATTEMPTS = parseInt(process.env.MAX_RETRY_ATTEMPTS || '2', 10);
// Delay between retries (in ms)
const RETRY_DELAY = parseInt(process.env.RETRY_DELAY || '3000', 10);

/**
 * Helper function to delay execution
 * @param {number} ms - Milliseconds to delay
 * @returns {Promise} - Promise that resolves after the delay
 */
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Send a query to the AI Processing Service
 * @param {string} query - The user's programming query
 * @param {object} metadata - Additional metadata for the request
 * @param {object} req - The original request object (for logging)
 * @param {number} retryAttempt - Current retry attempt (used internally)
 * @returns {Promise<object>} The AI service response
 */
export const processQuery = async (query, metadata = {}, req, retryAttempt = 0) => {
  try {
    // Get the AI service URL from metadata or environment variable
    const aiServiceUrl = metadata.aiServiceUrl ? 
      `${metadata.aiServiceUrl}/process` : 
      process.env.AI_SERVICE_URL || DEFAULT_AI_SERVICE_URL;
      
    console.log(`[AI-SERVICE] ${retryAttempt > 0 ? `Retry attempt ${retryAttempt}/${MAX_RETRY_ATTEMPTS}: ` : ''}Sending query to AI Processing Service at ${aiServiceUrl}: ${query.substring(0, 50)}...`);
    
    const startTime = Date.now();
    
    // First check if the AI service is up
    try {
      await axios.get(aiServiceUrl.replace('/process', '/health'), { timeout: 5000 });
    } catch (error) {
      console.error('[AI-SERVICE] Health check failed, service may be down');
      if (process.env.NODE_ENV === 'development') {
        return { 
          response: getFallbackResponse(query),
          source: 'fallback'
        };
      }
      throw new Error('AI service health check failed');
    }
    
    // Add more time for retries
    const timeoutForRequest = retryAttempt > 0 
      ? AI_SERVICE_TIMEOUT + (retryAttempt * 30000) // Add 30s per retry
      : AI_SERVICE_TIMEOUT;
      
    // Prepare the request to the AI service
    const response = await axios.post(
      aiServiceUrl,
      {
        query,
        metadata: {
          ...metadata,
          requestId: req.id || 'unknown'
        }
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': req.id || 'unknown'
        },
        timeout: timeoutForRequest
      }
    );
    
    const processingTime = Date.now() - startTime;
    console.log(`[AI-SERVICE] Received response from AI Service in ${processingTime}ms`);
    
    return {
      response: response.data.response,
      source: 'ai-service',
      metadata: {
        model: response.data.metadata?.model || 'unknown',
        processingTime,
        tokens: response.data.metadata?.tokens || { total: 0, prompt: 0, completion: 0 }
      }
    };
  } catch (error) {
    // Log the error
    logError(error, req, '[AI-SERVICE] Error processing query');
    
    // Check if this is a timeout error
    const isTimeout = error.code === 'ECONNABORTED' || 
                     (error.message && error.message.includes('timeout'));
    
    // If it's a timeout and we haven't reached max retries, try again
    if (isTimeout && retryAttempt < MAX_RETRY_ATTEMPTS) {
      console.log(`[AI-SERVICE] Request timed out. Retrying (${retryAttempt + 1}/${MAX_RETRY_ATTEMPTS})...`);
      
      // Wait before retrying
      await delay(RETRY_DELAY);
      
      // Retry with incremented retry count
      return processQuery(query, metadata, req, retryAttempt + 1);
    }
    
    // For development environments, provide a fallback response
    if (process.env.NODE_ENV === 'development') {
      console.log('[AI-SERVICE] Using fallback response in development mode');
      
      // If we've attempted retries, mention that in the fallback
      let fallbackResponse = getFallbackResponse(query);
      if (retryAttempt > 0) {
        fallbackResponse = `After ${retryAttempt + 1} attempts, the request still timed out. Using fallback response:\n\n${fallbackResponse}`;
      }
      
      return {
        response: fallbackResponse,
        source: 'fallback',
        metadata: {
          error: error.message,
          retryAttempts: retryAttempt
        }
      };
    }
    
    // In production, propagate the error
    throw error;
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