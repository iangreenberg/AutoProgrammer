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
  const [retryCount, setRetryCount] = useState(0)
  const [isAutoRetrying, setIsAutoRetrying] = useState(false)
  
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

  const handleSubmit = async (isRetry = false, currentRetryCount = 0) => {
    if (!query.trim()) return

    // If this is a new submission (not a retry), reset the retry count
    if (!isRetry) {
      setRetryCount(0)
      setIsAutoRetrying(false)
    } else {
      setRetryCount(currentRetryCount)
      setIsAutoRetrying(true)
    }

    setLoading(true)
    if (!isRetry) {
      setResponse('')
    } else {
      setResponse(prevResponse => prevResponse + '\n\nRetrying request... (Attempt ' + currentRetryCount + '/3)')
    }
    
    try {
      console.log('Sending query to API:', query, isRetry ? `(Retry attempt ${currentRetryCount})` : '');
      
      // Increase timeout for retries to give more time
      const timeoutMs = isRetry ? 90000 : 60000;
      const result = await api.post('/ask', { query }, { timeout: timeoutMs });
      
      console.log('Received response:', result);
      const responseText = result.data.response || 'No response received';
      setResponse(responseText)
      setConnectionStatus('connected')
      setErrorDetails('')
      setIsAutoRetrying(false)
      
      // Automatically save to Cursor if the electronAPI is available
      if (window.electronAPI?.saveToCursor) {
        try {
          console.log('Auto-saving response to Cursor...');
          await window.electronAPI.saveToCursor({
            content: responseText,
            query: query
          });
          console.log('Successfully auto-saved to Cursor');
        } catch (saveError) {
          console.error('Error auto-saving to Cursor:', saveError);
        }
      }
    } catch (error) {
      console.error('Error fetching response:', error);
      setConnectionStatus('disconnected');
      
      if (error.code === 'ECONNABORTED') {
        // Handle timeout error with auto-retry
        if (currentRetryCount < 3) {
          // Auto-retry up to 3 times
          const nextRetryCount = currentRetryCount + 1;
          setResponse(`Error: Request timed out. The AI service is taking longer than expected.\n\nAutomatically retrying (${nextRetryCount}/3)...`);
          setErrorDetails(`Retry ${nextRetryCount}/3 in progress. Please wait...`);
          
          // Wait a moment before retrying
          setTimeout(() => {
            handleSubmit(true, nextRetryCount);
          }, 2000);
        } else {
          // Give up after 3 retries
          setResponse('Error: Request timed out after multiple attempts. The AI service may be overloaded.');
          setErrorDetails('You can try again manually with a simpler query or try again later.');
          setIsAutoRetrying(false);
        }
      } else if (error.code === 'ERR_NETWORK') {
        setResponse('Error: Could not connect to the API Gateway.')
        setErrorDetails(`Make sure the API Gateway is available at ${API_GATEWAY_URL}`)
        setIsAutoRetrying(false);
      } else if (error.response) {
        setResponse(`Error ${error.response.status}: ${error.response.data.message || 'API error occurred.'}`)
        setErrorDetails(`Server responded with error: ${JSON.stringify(error.response.data)}`)
        setIsAutoRetrying(false);
      } else {
        setResponse('An unexpected error occurred while processing your request.')
        setErrorDetails(error.message)
        setIsAutoRetrying(false);
      }
    } finally {
      if (!isAutoRetrying) {
        setLoading(false)
      }
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
                  onClick={() => handleSubmit(false, 0)} 
                  disabled={loading || !query.trim() || connectionStatus !== 'connected'}
                >
                  {loading && !isAutoRetrying ? 'Thinking...' : 
                   isAutoRetrying ? `Auto-Retrying (${retryCount}/3)...` : 'Ask'}
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
