/**
 * AutoProgrammer API Gateway
 * Central hub for the microservices architecture
 * Acts as an intermediary between frontend and AI service
 */

import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';

// Import middleware modules
import { validateApiKey } from './middleware/auth.js';
import { validateQueryRequest } from './middleware/validation.js';
import { setupLogging, logRequest } from './middleware/logging.js';
import { notFoundHandler, errorHandler, timeoutHandler } from './middleware/error-handler.js';

// Import services
import { processQuery, getFallbackResponse } from './services/ai-service.js';

// Import rate limiter
import rateLimiter from './rate-limiter.js';

// Load environment variables
dotenv.config();

// Application setup
const app = express();
const PORT = process.env.PORT || 4000;
const FRONTEND_URLS = (process.env.FRONTEND_URLS || 'http://localhost:5173,http://localhost:5174').split(',');
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:5000';

// Add request ID to each request
app.use((req, res, next) => {
  req.id = uuidv4();
  res.setHeader('X-Request-ID', req.id);
  next();
});

// Configure middleware
// In development mode, we'll use a more permissive CORS policy
if (process.env.NODE_ENV === 'development') {
  console.log('Using development CORS settings (allowing all origins)');
  app.use(cors());
} else {
  app.use(cors({
    origin: FRONTEND_URLS,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
    credentials: true
  }));
}

app.use(bodyParser.json({ limit: '1mb' }));
app.use(bodyParser.urlencoded({ extended: true }));

// Setup request logging
setupLogging(app);

// Add rate limiting middleware
app.use(rateLimiter);

// Log all requests
app.use(logRequest);

// Add timeout middleware
app.use(timeoutHandler(30000)); // 30 second timeout

// Routes
// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'api-gateway',
    version: '1.0.0',
    ai_service: AI_SERVICE_URL
  });
});

// Documentation endpoint
app.get('/docs', (req, res) => {
  res.status(200).json({
    name: 'AutoProgrammer API Gateway',
    description: 'Central service for managing programming requests and responses',
    version: '1.0.0',
    endpoints: [
      { path: '/health', method: 'GET', description: 'Check service health' },
      { path: '/docs', method: 'GET', description: 'API documentation' },
      { path: '/ask', method: 'POST', description: 'Submit programming queries' }
    ]
  });
});

// Main endpoint for programming queries
app.post('/ask', [
  validateApiKey,
  validateQueryRequest
], async (req, res, next) => {
  const { query } = req.body;
  
  try {
    // Process the query with the AI service
    const result = await processQuery(query, {
      requestId: req.id,
      userAgent: req.headers['user-agent'],
      aiServiceUrl: AI_SERVICE_URL
    }, req);
    
    // Return the response
    return res.status(200).json({
      success: true,
      response: result.response,
      metadata: result.metadata
    });
  } catch (error) {
    // If the AI service is down and we're in development, use fallback
    if (error.status === 503 && process.env.NODE_ENV === 'development') {
      const fallback = getFallbackResponse(query);
      return res.status(200).json(fallback);
    }
    
    // Otherwise, pass to error handler
    error.statusCode = error.status || 500;
    next(error);
  }
});

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start the server
app.listen(PORT, () => {
  console.log(`
┌────────────────────────────────────────────────┐
│                                                │
│   AutoProgrammer API Gateway                   │
│   Running on http://localhost:${PORT}            │
│                                                │
│   Environment: ${process.env.NODE_ENV || 'development'}                   │
│   AI Service: ${AI_SERVICE_URL}         │
│   Frontend URLs: ${FRONTEND_URLS.join(', ')}    │
│   Press Ctrl+C to stop                         │
│                                                │
└────────────────────────────────────────────────┘
  `);
}); 