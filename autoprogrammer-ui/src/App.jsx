import { useState, useEffect } from 'react'
import Draggable from 'react-draggable'
import axios from 'axios'
import './App.css'

function App() {
  const [query, setQuery] = useState('')
  const [response, setResponse] = useState('')
  const [loading, setLoading] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  
  // Default position for the assistant
  const [position, setPosition] = useState({ x: 20, y: 20 })

  // Auto-open the assistant on first load
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsOpen(true);
    }, 500);
    
    return () => clearTimeout(timer);
  }, []);

  const handleQueryChange = (e) => {
    setQuery(e.target.value)
  }

  const handleSubmit = async () => {
    if (!query.trim()) return

    setLoading(true)
    setResponse('')
    
    try {
      const result = await axios.post('http://localhost:4000/ask', { query })
      setResponse(result.data.response || 'No response received')
    } catch (error) {
      console.error('Error fetching response:', error)
      setResponse('Error: Could not connect to the API. Make sure the API Gateway is running on localhost:4000.')
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

  return (
    <div className="app-container">
      <h1 className="app-title">AutoProgrammer UI</h1>
      
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
                  disabled={loading || !query.trim()}
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
