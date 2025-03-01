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

// Run cleanup every minute
setInterval(cleanupExpiredEntries, 60000);

/**
 * Rate limiting middleware
 * Limits requests based on client IP address
 */
function rateLimiter(req, res, next) {
  // Get client IP
  const ip = req.ip || 
             req.headers['x-forwarded-for'] || 
             req.connection.remoteAddress || 
             'unknown';
  
  // Initialize or update timestamp for this IP
  const now = Date.now();
  const lastTimestamp = ipTimestamps.get(ip) || 0;
  
  // Reset count if window has passed
  if (now - lastTimestamp > WINDOW_MS) {
    requestCounts.set(ip, 1);
    ipTimestamps.set(ip, now);
    return next();
  }
  
  // Increment request count
  const requestCount = (requestCounts.get(ip) || 0) + 1;
  requestCounts.set(ip, requestCount);
  ipTimestamps.set(ip, now);
  
  // Add rate limit headers
  res.setHeader('X-RateLimit-Limit', MAX_REQUESTS);
  res.setHeader('X-RateLimit-Remaining', Math.max(0, MAX_REQUESTS - requestCount));
  res.setHeader('X-RateLimit-Reset', Math.ceil((lastTimestamp + WINDOW_MS) / 1000));
  
  // Check if rate limit exceeded
  if (requestCount > MAX_REQUESTS) {
    return res.status(429).json({
      status: 'error',
      message: 'Rate limit exceeded. Please try again later.',
      retryAfter: Math.ceil((WINDOW_MS - (now - lastTimestamp)) / 1000)
    });
  }
  
  next();
}

export default rateLimiter; 