import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';

const app = express();
const port = 4000;

// Middleware
app.use(cors({
  origin: 'http://localhost:5174', // Match the Vite dev server port
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
app.use(bodyParser.json());

// Routes
app.get('/', (req, res) => {
  res.send('AutoProgrammer API Gateway is running');
});

// Handle AI assistant queries
app.post('/ask', (req, res) => {
  const { query } = req.body;
  
  if (!query) {
    return res.status(400).json({ error: 'Query is required' });
  }
  
  // Simple mock response for now
  const response = `You asked: "${query}"\n\nThis is a mock response from the API Gateway. In a real implementation, this would connect to an AI service.`;
  
  // Simulate a slight delay as if processing with an AI
  setTimeout(() => {
    res.json({ response });
  }, 1000);
});

// Start server
app.listen(port, () => {
  console.log(`API Gateway running at http://localhost:${port}`);
}); 