/**
 * Validation Middleware
 * Provides request validation and sanitization
 */

/**
 * Validate query request body
 * Ensures the request contains a valid query string
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
export const validateQueryRequest = (req, res, next) => {
  const { query } = req.body;
  
  // Check if query exists
  if (!query) {
    return res.status(400).json({
      success: false,
      error: 'Bad Request',
      message: 'Query is required'
    });
  }
  
  // Check if query is a string
  if (typeof query !== 'string') {
    return res.status(400).json({
      success: false,
      error: 'Bad Request',
      message: 'Query must be a string'
    });
  }
  
  // Check if query has content
  if (query.trim().length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Bad Request',
      message: 'Query cannot be empty'
    });
  }
  
  // Check if query exceeds maximum length
  if (query.length > 1500) {
    return res.status(400).json({
      success: false,
      error: 'Bad Request',
      message: 'Query exceeds maximum length of 1500 characters'
    });
  }
  
  // Sanitize query
  req.body.query = sanitizeQuery(query);
  
  next();
};

/**
 * Sanitize the query string
 * @param {string} query - The query to sanitize
 * @returns {string} The sanitized query
 */
function sanitizeQuery(query) {
  // Trim whitespace
  let sanitized = query.trim();
  
  // Replace multiple spaces with a single space
  sanitized = sanitized.replace(/\s+/g, ' ');
  
  // Remove any potentially dangerous characters
  sanitized = sanitized.replace(/[<>]/g, '');
  
  return sanitized;
} 