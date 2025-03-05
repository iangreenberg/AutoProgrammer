/**
 * Error Handler Middleware
 * Provides centralized error handling for the API Gateway
 */

import { logError } from './logging.js';
import { getFallbackResponse } from '../services/ai-service.js';

/**
 * Timeout middleware for request handling
 * @param {number} timeout - Timeout in milliseconds
 * @returns {Function} Express middleware
 */
export const timeoutHandler = (timeout = 30000) => {
  return (req, res, next) => {
    // Set a timeout for the request
    req.setTimeout(timeout, () => {
      const err = new Error('Request timeout - the server took too long to process your request');
      err.statusCode = 408;
      err.isTimeout = true;
      next(err);
    });
    next();
  };
};

/**
 * 404 Not Found handler for undefined routes
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
export const notFoundHandler = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

/**
 * Check if an error is a timeout error
 * @param {Error} err - Error object
 * @returns {boolean} True if it's a timeout error
 */
const isTimeoutError = (err) => {
  return (
    err.isTimeout || 
    err.statusCode === 408 || 
    err.code === 'ECONNABORTED' || 
    err.code === 'ETIMEDOUT' ||
    (err.message && (
      err.message.includes('timeout') || 
      err.message.includes('timed out')
    ))
  );
};

/**
 * Global error handler for the application
 * @param {Error} err - Error object
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
export const errorHandler = (err, req, res, next) => {
  // Log the error
  logError(err, req);

  // Set status code
  const statusCode = err.statusCode || err.status || 500;

  // Check if this is a timeout error
  const isTimeout = isTimeoutError(err);
  
  // For timeout errors in development mode, provide a fallback response
  if (isTimeout && process.env.NODE_ENV === 'development' && req.body?.query) {
    console.log('[ERROR-HANDLER] Timeout detected, providing fallback response');
    
    // Get the query from the request body
    const query = req.body.query;
    
    // Return a fallback response with 200 status
    return res.status(200).json({
      success: true,
      response: `The AI service timed out, but here's a fallback response:\n\n${getFallbackResponse(query)}`,
      metadata: {
        source: 'fallback',
        error: 'timeout',
        message: err.message
      }
    });
  }

  // Format error response
  const errorResponse = {
    success: false,
    error: statusCodeToMessage(statusCode),
    message: err.message || 'An unexpected error occurred'
  };

  // Add stack trace in development
  if (process.env.NODE_ENV === 'development') {
    errorResponse.stack = err.stack;
    
    // Add additional error details if available
    if (err.original) {
      errorResponse.original = {
        message: err.original.message,
        ...(err.original.response?.data && { data: err.original.response.data }),
        ...(err.original.code && { code: err.original.code })
      };
    }
  }

  // Send response
  res.status(statusCode).json(errorResponse);
};

/**
 * Convert HTTP status code to readable message
 * @param {number} statusCode - HTTP status code
 * @returns {string} Human-readable error type
 */
function statusCodeToMessage(statusCode) {
  const statusMessages = {
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    408: 'Request Timeout',
    429: 'Too Many Requests',
    500: 'Internal Server Error',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Timeout'
  };

  return statusMessages[statusCode] || 'Error';
} 