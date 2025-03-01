/**
 * Logging Middleware
 * Provides centralized logging for the API Gateway
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import morgan from 'morgan';

// Get directory name
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Ensure logs directory exists
const logsDir = path.join(__dirname, '..', 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Create log streams
const accessLogStream = fs.createWriteStream(
  path.join(logsDir, 'access.log'),
  { flags: 'a' }
);

const errorLogStream = fs.createWriteStream(
  path.join(logsDir, 'error.log'),
  { flags: 'a' }
);

/**
 * Set up logging for the Express application
 * @param {Object} app - Express application object
 */
export const setupLogging = (app) => {
  // Log all requests to access.log
  app.use(morgan(':date[iso] :method :url :status :res[content-length] - :response-time ms :remote-addr - :req[X-Request-ID]', { 
    stream: accessLogStream 
  }));
  
  // Log HTTP requests to console in development
  if (process.env.NODE_ENV === 'development') {
    app.use(morgan(':method :url :status :response-time ms - :req[X-Request-ID]'));
  }
};

/**
 * Log individual requests with details
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
export const logRequest = (req, res, next) => {
  const start = Date.now();
  
  // Log request details
  console.log(`[${req.id}] ${req.method} ${req.url} - ${new Date().toISOString()}`);
  if (req.method === 'POST' && req.body) {
    // Log request body for debugging (redact sensitive data in production)
    if (process.env.NODE_ENV === 'development') {
      const sanitizedBody = { ...req.body };
      // Redact sensitive fields
      if (sanitizedBody.api_key) sanitizedBody.api_key = '[REDACTED]';
      if (sanitizedBody.authorization) sanitizedBody.authorization = '[REDACTED]';
      
      console.log(`[${req.id}] Request Body:`, JSON.stringify(sanitizedBody).substring(0, 200) + (JSON.stringify(sanitizedBody).length > 200 ? '...' : ''));
    }
  }
  
  // Log response when finished
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${req.id}] Response: ${res.statusCode} - ${duration}ms`);
  });
  
  next();
};

/**
 * Log errors to file and console
 * @param {Error} err - Error object
 * @param {Object} req - Express request object
 * @param {string} context - Optional context message
 */
export const logError = (err, req, context = 'Error') => {
  const timestamp = new Date().toISOString();
  const requestId = req?.id || 'NO_REQ_ID';
  const method = req?.method || 'UNKNOWN';
  const url = req?.url || 'UNKNOWN';
  
  // Format error message
  const errorMessage = `[${timestamp}] [${requestId}] [ERROR] ${context}: ${method} ${url} - ${err.message}`;
  
  // Log to error file
  errorLogStream.write(errorMessage + '\n');
  if (err.stack) {
    errorLogStream.write(`[${timestamp}] [${requestId}] [STACK] ${err.stack}\n`);
  }
  
  // Also log to console in development
  console.error(errorMessage);
  if (process.env.NODE_ENV === 'development' && err.stack) {
    console.error(err.stack);
  }
  
  // Log original error if exists
  if (err.original) {
    const originalMessage = `[${timestamp}] [${requestId}] [ORIGINAL] ${err.original.message}`;
    errorLogStream.write(originalMessage + '\n');
    
    if (process.env.NODE_ENV === 'development') {
      console.error('Original error:', err.original.message);
    }
  }
}; 