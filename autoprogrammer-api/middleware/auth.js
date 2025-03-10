/**
 * Authentication Middleware
 * Handles API key validation and authorization
 */

import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

/**
 * Validate API key for protected routes
 * Skips validation in development mode
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
export const validateApiKey = (req, res, next) => {
  // Always skip API key validation in development mode
  if (process.env.NODE_ENV === 'development') {
    console.log(`[${req.id}] [AUTH] API key validation skipped in development mode`);
    return next();
  }
  
  // Get API key from request
  const apiKey = req.headers.authorization || req.headers['x-api-key'];

  // Validate API key
  if (!apiKey || !validateKey(apiKey)) {
    console.log(`[${req.id}] [AUTH] Invalid or missing API key`);
    return res.status(401).json({
      success: false,
      error: 'Unauthorized',
      message: 'Invalid or missing API key'
    });
  }
  
  // API key is valid
  next();
};

/**
 * Verify if the API key is valid
 * @param {string} apiKey - The API key to validate
 * @returns {boolean} True if valid, false otherwise
 */
function validateKey(apiKey) {
  // Remove "Bearer " prefix if present
  const key = apiKey.startsWith('Bearer ') ? apiKey.substring(7) : apiKey;
  
  // Simple validation - compare with environment variable
  return key === process.env.API_KEY;
}

// Additional auth middleware can be added here in the future
// For example: JWT validation, role-based access control, etc. 