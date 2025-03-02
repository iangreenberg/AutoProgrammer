/**
 * AutoProgrammer AI Processing Service
 * Processes programming queries through DeepSeek R1 API
 * and formats responses into structured development strategies
 */

import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import morgan from 'morgan';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Import services
import { processWithDeepSeek } from './services/deepseek-service.js';
import { formatResponse } from './utils/formatter.js';

// Import rate limiter
import { rateLimiter } from './rate-limiter.js';

// Initialize environment variables
dotenv.config();

// Configuration
const PORT = process.env.PORT || 5000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const GATEWAY_URL = process.env.GATEWAY_URL || 'http://localhost:4000';

// Set up the Express app
const app = express();

// Use rate limiter middleware
app.use(rateLimiter);

// Create logs directory if it doesn't exist
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Configure request logging
const accessLogStream = fs.createWriteStream(
  path.join(logsDir, 'access.log'),
  { flags: 'a' }
);

// Add request ID to each request
app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] || uuidv4();
  res.setHeader('X-Request-ID', req.id);
  next();
});

// Use Morgan for logging
app.use(morgan(':date[iso] :method :url :status :res[content-length] - :response-time ms :remote-addr - :req[X-Request-ID]', { 
  stream: accessLogStream 
}));
app.use(morgan(':method :url :status :response-time ms - :req[X-Request-ID]'));

// Configure CORS
app.use(cors({
  origin: GATEWAY_URL,
  methods: ['POST', 'GET', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  credentials: true,
  maxAge: 86400 // 24 hours
}));

// Configure request parsing
app.use(bodyParser.json({ limit: '1mb' }));
app.use(bodyParser.urlencoded({ extended: true }));

// API Key validation middleware
const validateApiKey = (req, res, next) => {
  // Skip API key validation in development mode
  if (NODE_ENV === 'development') {
    return next();
  }

  const apiKey = req.headers.authorization;
  if (!apiKey || !apiKey.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Missing or invalid API key'
    });
  }

  // In production, validate API key here
  // Replace with actual API key validation logic
  next();
};

// Request validation middleware
const validateRequest = (req, res, next) => {
  const { query } = req.body;
  
  if (!query || typeof query !== 'string' || query.trim().length === 0) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Query is required and must be a non-empty string'
    });
  }
  
  if (query.length > 1500) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Query exceeds maximum length of 1500 characters'
    });
  }
  
  next();
};

// Routes
// Health check endpoint
app.get('/health', (req, res) => {
  const healthStatus = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'ai-processor',
    version: '1.0.0',
    environment: NODE_ENV,
    deepseek: {
      model: process.env.DEEPSEEK_MODEL || 'deepseek-coder-plus',
      api: Boolean(process.env.DEEPSEEK_API_KEY) ? 'configured' : 'not configured'
    }
  };
  
  res.status(200).json(healthStatus);
});

// Main processing endpoint
app.post('/process', [validateRequest, validateApiKey], async (req, res) => {
  const { query } = req.body;
  const startTime = Date.now();
  
  try {
    console.log(`[${req.id}] Processing query: ${query.substring(0, 50)}...`);
    
    // Process with DeepSeek API
    const deepseekResponse = await processWithDeepSeek(query, req.id);
    
    // Format the response
    const formattedResponse = formatResponse(deepseekResponse, query);
    
    // Calculate processing time
    const processingTime = Date.now() - startTime;
    
    // Send response
    res.status(200).json({
      success: true,
      response: formattedResponse,
      metadata: {
        requestId: req.id,
        processingTime,
        source: 'deepseek-r1'
      }
    });
    
    console.log(`[${req.id}] Response sent in ${processingTime}ms`);
  } catch (error) {
    console.error(`[${req.id}] Error:`, error.message);
    
    res.status(error.status || 500).json({
      success: false,
      error: error.type || 'Internal Server Error',
      message: error.message || 'An unexpected error occurred',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Handle 404s
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested endpoint does not exist'
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`
┌────────────────────────────────────────────────┐
│                                                │
│   AutoProgrammer AI Processing Service         │
│   Running on http://localhost:${PORT}            │
│                                                │
│   Environment: ${NODE_ENV}                   │
│   Gateway URL: ${GATEWAY_URL}          │
│   DeepSeek Model: ${process.env.DEEPSEEK_MODEL || 'deepseek-coder-plus'}        │
│   Press Ctrl+C to stop                         │
│                                                │
└────────────────────────────────────────────────┘
  `);
}); 