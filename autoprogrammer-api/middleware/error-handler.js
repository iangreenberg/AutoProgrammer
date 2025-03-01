/**
 * Error Handler Middleware
 * Provides centralized error handling for the API Gateway
 */

import { logError } from './logging.js';

/**
 * Timeout middleware for request handling
 * @param {number} timeout - Timeout in milliseconds
 * @returns {Function} Express middleware
 */
export const timeoutHandler = (timeout = 30000) => {
  return (req, res, next) => {
    // Set a timeout for the request
    req.setTimeout(timeout, () => {
      const err = new Error('Request timeout');
      err.statusCode = 408;
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