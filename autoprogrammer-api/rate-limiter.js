/**
 * Rate Limiter Module for AutoProgrammer API Gateway
 * Implements a configurable in-memory rate limiting middleware
 */

import 'dotenv/config';

// Configuration defaults with fallbacks to environment variables
const MAX_REQUESTS = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '60', 10);
const WINDOW_MS = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10);

// Store for tracking request counts by IP
const requestCounts = new Map();
const ipTimestamps = new Map();

/**
 * Cleans up expired entries from the request counts map
 */
function cleanupExpiredEntries() {
  const now = Date.now();
  
  for (const [ip, timestamp] of ipTimestamps.entries()) {
    if (now - timestamp > WINDOW_MS) {
      requestCounts.delete(ip);
      ipTimestamps.delete(ip);
    }
  }
}

/**
 * Rate limiter middleware
 * Limits requests based on IP address
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
function rateLimiter(req, res, next) {
  const ip = req.ip || req.connection.remoteAddress;
  
  // Clean up expired entries periodically
  cleanupExpiredEntries();
  
  // Get current count for this IP
  const currentCount = requestCounts.get(ip) || 0;
  
  if (currentCount >= MAX_REQUESTS) {
    return res.status(429).json({
      error: 'Too many requests',
      message: `Rate limit exceeded. Please try again in ${Math.ceil(WINDOW_MS / 1000)} seconds.`
    });
  }
  
  // Update count and timestamp
  requestCounts.set(ip, currentCount + 1);
  ipTimestamps.set(ip, Date.now());
  
  next();
}

// Set interval to clean up expired entries regularly
setInterval(cleanupExpiredEntries, WINDOW_MS);

// Export the rate limiter middleware
export { rateLimiter };
export default rateLimiter; 