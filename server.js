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
import rateLimiter from './rate-limiter.js';

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