import { useState, useEffect } from 'react'
import Draggable from 'react-draggable'
import axios from 'axios'
import './App.css'

// API base URLs - use relative paths for Netlify Functions
const API_GATEWAY_URL = import.meta.env.VITE_API_GATEWAY_URL || '/api';
const IS_DEV = import.meta.env.MODE === 'development';

// Default headers for API requests
const API_HEADERS = {
  'Accept': 'application/json',
  'Content-Type': 'application/json'
};

// Add API key in production only
if (!IS_DEV && import.meta.env.VITE_API_KEY) {
  API_HEADERS.Authorization = import.meta.env.VITE_API_KEY;
}

// Create axios instance with default config
const api = axios.create({
  baseURL: API_GATEWAY_URL,
  headers: API_HEADERS,
  timeout: 60000,
  withCredentials: false
});

function App() {
  const [query, setQuery] = useState('')
  const [response, setResponse] = useState('')
  const [loading, setLoading] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [connectionStatus, setConnectionStatus] = useState('unknown') // 'connected', 'disconnected', 'unknown'
  const [errorDetails, setErrorDetails] = useState('')
  
  // Default position for the assistant
  const [position, setPosition] = useState({ x: 20, y: 20 })

  // Auto-open the assistant on first load and check connection
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsOpen(true);
    }, 500);
    
    // Check API connection on mount
    checkApiConnection();
    
    // Set up periodic connection check
    const connectionCheckInterval = setInterval(checkApiConnection, 30000);
    
    return () => {
      clearTimeout(timer);
      clearInterval(connectionCheckInterval);
    };
  }, []);
  
  // Check if the API Gateway is available
  const checkApiConnection = async () => {
    try {
      console.log('Checking API connection to:', `${API_GATEWAY_URL}/health`);
      const response = await api.get('/health');
      
      if (response.status === 200) {
        setConnectionStatus('connected');
        setErrorDetails('');
        console.log('API connection successful');
      } else {
        setConnectionStatus('disconnected');
        setErrorDetails(`API Gateway returned unexpected status: ${response.status}`);
        console.error('API connection error:', response.status);
      }
    } catch (error) {
      setConnectionStatus('disconnected');
      console.error('API connection check failed:', error);
      
      if (error.code === 'ECONNABORTED') {
        setErrorDetails('Connection timed out. API Gateway may be unavailable.');
      } else if (error.code === 'ERR_NETWORK') {
        setErrorDetails(`Cannot connect to API Gateway at ${API_GATEWAY_URL}`);
      } else {
        setErrorDetails(`Error connecting to API Gateway: ${error.message}`);
      }
    }
  };

  const handleQueryChange = (e) => {
    setQuery(e.target.value)
  }

  const handleSubmit = async () => {
    if (!query.trim()) return

    setLoading(true)
    setResponse('')
    
    try {
      console.log('Sending query to API:', query);
      const result = await api.post('/ask', { query });
      
      console.log('Received response:', result);
      setResponse(result.data.response || 'No response received')
      setConnectionStatus('connected')
      setErrorDetails('')
    } catch (error) {
      console.error('Error fetching response:', error);
      setConnectionStatus('disconnected');
      
      if (error.code === 'ECONNABORTED') {
        setResponse('Error: Request timed out. The AI service may be taking too long to respond.')
        setErrorDetails('Try again with a simpler query or check if the AI service is functioning properly.')
      } else if (error.code === 'ERR_NETWORK') {
        setResponse('Error: Could not connect to the API Gateway.')
        setErrorDetails(`Make sure the API Gateway is available at ${API_GATEWAY_URL}`)
      } else if (error.response) {
        setResponse(`Error ${error.response.status}: ${error.response.data.message || 'API error occurred.'}`)
        setErrorDetails(`Server responded with error: ${JSON.stringify(error.response.data)}`)
      } else {
        setResponse('An unexpected error occurred while processing your request.')
        setErrorDetails(error.message)
      }
    } finally {
      setLoading(false)
    }
  }

  const toggleAssistant = () => {
    setIsOpen(!isOpen)
  }

  const handleDragStop = (e, data) => {
    setPosition({ x: data.x, y: data.y })
  }

  // Status indicator component
  const ConnectionStatus = () => {
    let statusClass = 'status-unknown';
    let statusText = 'Checking connection...';
    
    if (connectionStatus === 'connected') {
      statusClass = 'status-connected';
      statusText = 'Connected to API';
    } else if (connectionStatus === 'disconnected') {
      statusClass = 'status-disconnected';
      statusText = 'Disconnected';
    }
    
    return (
      <div className="connection-status-container">
        <div className={`connection-status ${statusClass}`}>
          <span className="status-indicator"></span>
          <span className="status-text">{statusText}</span>
        </div>
        {errorDetails && connectionStatus === 'disconnected' && (
          <div className="error-details">{errorDetails}</div>
        )}
        {connectionStatus === 'disconnected' && (
          <button onClick={checkApiConnection} className="retry-button">
            Retry Connection
          </button>
        )}
      </div>
    );
  };

  return (
    <div className="app-container">
      <h1 className="app-title">AutoProgrammer UI</h1>
      
      <ConnectionStatus />
      
      <div className="welcome-message">
        <p>Welcome to the AutoProgrammer assistant. Click the robot icon to interact with the AI assistant.</p>
        <p>The assistant will help you with software development questions and provide structured responses.</p>
      </div>
      
      <Draggable 
        handle=".handle" 
        defaultPosition={position} 
        onStop={handleDragStop}
        bounds="body"
      >
        <div className={`assistant-container ${isOpen ? 'open' : 'closed'}`}>
          <div className="handle" onClick={toggleAssistant}>
            <span role="img" aria-label="AI Assistant">🤖</span>
            {!isOpen && <div className="assistant-tooltip">Click me!</div>}
          </div>
          
          {isOpen && (
            <div className="assistant-content">
              <h3>AI Programming Assistant</h3>
              
              <div className="input-container">
                <textarea 
                  value={query} 
                  onChange={handleQueryChange} 
                  placeholder="Ask a software development question..."
                  rows={3}
                />
                <button 
                  onClick={handleSubmit} 
                  disabled={loading || !query.trim() || connectionStatus !== 'connected'}
                >
                  {loading ? 'Thinking...' : 'Ask'}
                </button>
              </div>
              
              {response && (
                <div className="response-container">
                  <h4>Response:</h4>
                  <div className="response-content">
                    {response}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </Draggable>
    </div>
  )
}

export default App
