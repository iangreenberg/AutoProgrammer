#!/bin/bash

echo "=========================================================="
echo "        Advanced UI Fix - Blank Page Issue"
echo "=========================================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set up the project root for reference
PROJECT_ROOT="$(pwd)"

# First, stop ALL services
echo -e "${YELLOW}Stopping ALL services...${NC}"
pkill -f "node.*vite" || true
pkill -f "node.*gateway.js" || true
pkill -f "node.*server.js" || true
sleep 2

# Force kill any processes on ALL ports
for port in 5173 5174 4000 5000; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo -e "Killing process $pid using port $port"
        kill -9 $pid 2>/dev/null || true
        sleep 1
    fi
done

# Verify ports are free
for port in 5173 5174 4000 5000; do
    if lsof -i:$port &>/dev/null; then
        echo -e "${RED}Port $port is still in use. Please check manually with 'lsof -i:$port'${NC}"
    else
        echo -e "${GREEN}Port $port is free${NC}"
    fi
done

# Change to UI directory and rebuild dependencies
echo -e "\n${YELLOW}Rebuilding UI...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ui" || {
    echo -e "${RED}Error: UI directory not found at ${PROJECT_ROOT}/autoprogrammer-ui${NC}"
    exit 1
}

# Clean npm cache and reinstall dependencies
echo -e "Cleaning npm cache and reinstalling dependencies..."
rm -rf node_modules
rm -rf .vite
npm cache clean --force
npm install
echo -e "${GREEN}Dependencies reinstalled${NC}"

# Create a minimal functional index.html
echo -e "Creating a minimal index.html..."
cat > "index.html" << EOL
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AutoProgrammer</title>
    <script>
      // Error logging
      window.addEventListener('error', function(e) {
        console.error('Global error:', e.message, 'at', e.filename, ':', e.lineno);
        const errorDiv = document.createElement('div');
        errorDiv.style.backgroundColor = '#ffdddd';
        errorDiv.style.padding = '20px';
        errorDiv.style.margin = '20px';
        errorDiv.style.border = '1px solid red';
        errorDiv.style.borderRadius = '5px';
        errorDiv.innerHTML = '<h3>JavaScript Error:</h3><pre>' + 
          e.message + '\nAt: ' + e.filename + ':' + e.lineno + '</pre>';
        document.body.appendChild(errorDiv);
      });

      // React loading check
      window.addEventListener('DOMContentLoaded', function() {
        setTimeout(function() {
          const root = document.getElementById('root');
          if (root && root.children.length === 0) {
            console.error('React did not render anything in the root element');
            const errorDiv = document.createElement('div');
            errorDiv.style.backgroundColor = '#fff3cd';
            errorDiv.style.padding = '20px';
            errorDiv.style.margin = '20px';
            errorDiv.style.border = '1px solid #ffeeba';
            errorDiv.style.borderRadius = '5px';
            errorDiv.innerHTML = '<h3>UI Loading Issue</h3>' +
              '<p>React did not render anything in the root element. ' +
              'Check the console for more details.</p>' +
              '<p><a href="/debug-ui.html">Click here for debugging tools</a></p>';
            document.body.appendChild(errorDiv);
          }
        }, 3000);
      });
    </script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOL
echo -e "${GREEN}Enhanced index.html created${NC}"

# Create .env file with proper API URL
echo -e "Creating .env file with API Gateway URL..."
cat > ".env" << EOL
VITE_API_GATEWAY_URL=http://localhost:4000
EOL
echo -e "${GREEN}API Gateway URL configured${NC}"

# Create a debug UI page
echo -e "Creating debug-ui.html..."
mkdir -p public
cat > "public/debug-ui.html" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Advanced UI Debug</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
        }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .container {
            border: 1px solid #ddd;
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
        }
        button {
            background-color: #4CAF50;
            color: white;
            padding: 10px 15px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            margin-top: 10px;
        }
        button:hover {
            background-color: #45a049;
        }
        pre {
            background-color: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        #error-console {
            background-color: #333;
            color: #f0f0f0;
            padding: 15px;
            border-radius: 5px;
            margin-top: 10px;
            max-height: 300px;
            overflow-y: auto;
            font-family: monospace;
        }
        .error-line { color: #ff6b6b; }
        .warn-line { color: #feca57; }
        .info-line { color: #54a0ff; }
        .tool-section {
            background-color: #f8f9fa;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
            border-left: 4px solid #4CAF50;
        }
    </style>
</head>
<body>
    <h1>Advanced UI Debugging</h1>
    
    <div class="container">
        <h2>System Information</h2>
        <div class="tool-section">
            <h3>Browser Details</h3>
            <div id="browser-info"></div>
        </div>
        
        <div class="tool-section">
            <h3>Console Log Capture</h3>
            <p>This will show console errors from this page and from the main UI if you reload it after enabling capture.</p>
            <button onclick="enableConsoleCapture()">Enable Console Capture</button>
            <button onclick="clearConsole()">Clear Console</button>
            <div id="error-console"></div>
        </div>
    </div>
    
    <div class="container">
        <h2>Troubleshooting Tools</h2>
        
        <div class="tool-section">
            <h3>1. Test Static Content Serving</h3>
            <p>This checks if the Vite server can correctly serve static content.</p>
            <button onclick="testStaticContent()">Test Static Content</button>
            <div id="static-test-result"></div>
        </div>
        
        <div class="tool-section">
            <h3>2. Test API Gateway Connection</h3>
            <p>Check if the API Gateway is accessible from the browser.</p>
            <button onclick="testAPIConnection()">Test API Connection</button>
            <div id="api-test-result"></div>
        </div>
        
        <div class="tool-section">
            <h3>3. Test React DOM Operations</h3>
            <p>Test if React DOM operations work correctly in your browser.</p>
            <button onclick="testReactDOM()">Test React DOM</button>
            <div id="react-dom-container"></div>
        </div>
        
        <div class="tool-section">
            <h3>4. Clean Browser Cache & Storage</h3>
            <button onclick="clearBrowserData()">Clear All Browser Data</button>
            <div id="clear-result"></div>
        </div>
    </div>
    
    <div class="container">
        <h2>Next Steps</h2>
        <p>After running the tests above:</p>
        <ol>
            <li>Check for any errors in the console log capture</li>
            <li>Make sure all tests pass successfully</li>
            <li>Try the minimal React test page: <a href="/minimal-react.html">Minimal React Test</a></li>
            <li>If that works, return to the main app: <a href="/">Main Application</a></li>
        </ol>
    </div>

    <!-- Load React for testing -->
    <script src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
    
    <script>
        // Display browser information
        function showBrowserInfo() {
            const browserInfo = document.getElementById('browser-info');
            browserInfo.innerHTML = `
                <p><strong>User Agent:</strong> ${navigator.userAgent}</p>
                <p><strong>Platform:</strong> ${navigator.platform}</p>
                <p><strong>Cookies Enabled:</strong> ${navigator.cookieEnabled}</p>
                <p><strong>Language:</strong> ${navigator.language}</p>
                <p><strong>URL:</strong> ${window.location.href}</p>
            `;
        }
        
        // Console log capture
        function enableConsoleCapture() {
            const consoleDiv = document.getElementById('error-console');
            consoleDiv.innerHTML = '<div class="info-line">Console logging enabled. Check here for errors...</div>';
            
            // Save original console methods
            const originalConsole = {
                log: console.log,
                error: console.error,
                warn: console.warn,
                info: console.info
            };
            
            // Override console methods
            console.error = function() {
                originalConsole.error.apply(console, arguments);
                const errorMsg = Array.from(arguments).join(' ');
                consoleDiv.innerHTML += `<div class="error-line">ERROR: ${errorMsg}</div>`;
            };
            
            console.warn = function() {
                originalConsole.warn.apply(console, arguments);
                const warnMsg = Array.from(arguments).join(' ');
                consoleDiv.innerHTML += `<div class="warn-line">WARNING: ${warnMsg}</div>`;
            };
            
            console.log = function() {
                originalConsole.log.apply(console, arguments);
                const logMsg = Array.from(arguments).join(' ');
                consoleDiv.innerHTML += `<div>${logMsg}</div>`;
            };
            
            console.info = function() {
                originalConsole.info.apply(console, arguments);
                const infoMsg = Array.from(arguments).join(' ');
                consoleDiv.innerHTML += `<div class="info-line">INFO: ${infoMsg}</div>`;
            };
            
            window.addEventListener('error', function(e) {
                consoleDiv.innerHTML += `<div class="error-line">UNCAUGHT ERROR: ${e.message} at ${e.filename}:${e.lineno}</div>`;
            });
            
            consoleDiv.innerHTML += '<div class="info-line">Now reload the main app page to capture its errors</div>';
        }
        
        function clearConsole() {
            document.getElementById('error-console').innerHTML = '<div class="info-line">Console cleared</div>';
        }
        
        // Test static content
        function testStaticContent() {
            const result = document.getElementById('static-test-result');
            result.innerHTML = '<p>Testing static content serving...</p>';
            
            // Create a timestamp to avoid caching
            const timestamp = new Date().getTime();
            
            // Test fetching a static file
            fetch('/vite.svg?' + timestamp)
                .then(response => {
                    if (response.ok) {
                        result.innerHTML = '<p class="success">✓ Static content is being served correctly</p>';
                        // Display the image
                        result.innerHTML += '<p>Here is the Vite logo:</p><img src="/vite.svg" alt="Vite logo" height="50" />';
                    } else {
                        result.innerHTML = '<p class="error">✗ Failed to fetch static content (HTTP status: ' + response.status + ')</p>';
                    }
                })
                .catch(error => {
                    result.innerHTML = '<p class="error">✗ Error fetching static content: ' + error.message + '</p>';
                });
        }
        
        // Test API Gateway connection
        function testAPIConnection() {
            const result = document.getElementById('api-test-result');
            result.innerHTML = '<p>Testing connection to API Gateway...</p>';
            
            fetch('http://localhost:4000/health')
                .then(response => {
                    if (response.ok) {
                        return response.json().catch(() => 'OK');
                    }
                    throw new Error('Network response was not ok: ' + response.status);
                })
                .then(data => {
                    result.innerHTML = '<p class="success">✓ API Gateway is accessible</p>';
                    result.innerHTML += '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                })
                .catch(error => {
                    result.innerHTML = '<p class="error">✗ Error accessing API Gateway: ' + error.message + '</p>';
                    result.innerHTML += '<p>Make sure the API Gateway is running on http://localhost:4000</p>';
                });
        }
        
        // Test React DOM operations
        function testReactDOM() {
            const container = document.getElementById('react-dom-container');
            container.innerHTML = '<p>Testing React DOM operations...</p>';
            
            try {
                if (typeof React !== 'undefined' && typeof ReactDOM !== 'undefined') {
                    // Create a simple React component
                    const element = React.createElement('div', null, [
                        React.createElement('h4', null, 'React DOM Test'),
                        React.createElement('p', { className: 'success' }, 
                            '✓ React DOM operations are working correctly (React v' + React.version + ')'),
                        React.createElement('button', { 
                            onClick: function() { alert('React event handling works!'); },
                            style: { marginTop: '10px' }
                        }, 'Test React Events')
                    ]);
                    
                    // Render the component
                    const root = document.createElement('div');
                    container.innerHTML = '';
                    container.appendChild(root);
                    ReactDOM.render(element, root);
                } else {
                    container.innerHTML = '<p class="error">✗ React is not available</p>';
                }
            } catch (e) {
                container.innerHTML = '<p class="error">✗ Error testing React: ' + e.message + '</p>';
                console.error('React DOM test error:', e);
            }
        }
        
        // Clear browser data
        function clearBrowserData() {
            const result = document.getElementById('clear-result');
            try {
                // Clear localStorage
                localStorage.clear();
                
                // Clear sessionStorage
                sessionStorage.clear();
                
                // Clear cookies for this domain
                document.cookie.split(";").forEach(function(c) {
                    document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
                });
                
                // Report success
                result.innerHTML = '<p class="success">✓ Browser storage cleared successfully</p>';
                result.innerHTML += '<p>For a complete cache clear, please also manually clear your browser cache:</p>';
                result.innerHTML += '<ul>' +
                    '<li><strong>Chrome:</strong> Settings > Privacy and Security > Clear browsing data</li>' +
                    '<li><strong>Firefox:</strong> Options > Privacy & Security > Cookies and Site Data > Clear Data</li>' +
                    '<li><strong>Safari:</strong> Preferences > Privacy > Manage Website Data > Remove All</li>' +
                    '</ul>';
            } catch (e) {
                result.innerHTML = '<p class="error">✗ Error clearing browser data: ' + e.message + '</p>';
            }
        }
        
        // Run on page load
        document.addEventListener('DOMContentLoaded', function() {
            showBrowserInfo();
        });
    </script>
</body>
</html>
EOL
echo -e "${GREEN}Debug UI page created${NC}"

# Create a minimal React test page
echo -e "Creating minimal-react.html..."
cat > "public/minimal-react.html" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minimal React Test</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        .app-container {
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            margin-top: 20px;
        }
        button {
            background-color: #4CAF50;
            color: white;
            padding: 8px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-right: 5px;
        }
        #counter {
            font-size: 2em;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>Minimal React Test</h1>
    <p>This page tests if React works correctly in your browser environment.</p>
    
    <div id="root"></div>
    
    <script src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
    <script>
        // Simple React component to test functionality
        function App() {
            const [count, setCount] = React.useState(0);
            const [message, setMessage] = React.useState('React is working correctly!');
            
            React.useEffect(() => {
                console.log('React useEffect hook executed');
            }, []);
            
            return React.createElement('div', { className: 'app-container' }, [
                React.createElement('h2', null, 'React Test Component'),
                React.createElement('p', null, message),
                React.createElement('div', { id: 'counter' }, count),
                React.createElement('div', null, [
                    React.createElement('button', {
                        onClick: () => setCount(count + 1),
                    }, 'Increment'),
                    React.createElement('button', {
                        onClick: () => setCount(count - 1),
                    }, 'Decrement'),
                    React.createElement('button', {
                        onClick: () => setCount(0),
                    }, 'Reset')
                ]),
                React.createElement('p', { style: { marginTop: '20px' } }, [
                    'If you can see this component and the buttons work, React is functioning correctly in your browser. ',
                    React.createElement('a', { href: '/' }, 'Return to main app')
                ])
            ]);
        }
        
        // Render the app
        const domContainer = document.getElementById('root');
        ReactDOM.render(React.createElement(App), domContainer);
    </script>
</body>
</html>
EOL
echo -e "${GREEN}Minimal React test page created${NC}"

# Update Vite config to force port 5173
echo -e "Updating vite.config.js..."
cat > "vite.config.js" << EOL
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: false, // Allow fallback to next available port
    cors: true,
    hmr: {
      overlay: true // Show errors as overlay in browser
    }
  }
})
EOL
echo -e "${GREEN}Vite configuration updated${NC}"

# Restart services one by one
echo -e "\n${YELLOW}Starting services one by one...${NC}"

# Start AI Service
echo -e "\n${YELLOW}Starting AI Service...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ai-service" || {
    echo -e "${RED}Error: AI Service directory not found at ${PROJECT_ROOT}/autoprogrammer-ai-service${NC}"
    exit 1
}
NODE_ENV=development npm run dev > "${PROJECT_ROOT}/ai-debug.log" 2>&1 &
AI_PID=$!
echo -e "${GREEN}AI Service started with PID $AI_PID${NC}"
sleep 3

# Start API Gateway
echo -e "\n${YELLOW}Starting API Gateway...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-api" || {
    echo -e "${RED}Error: API directory not found at ${PROJECT_ROOT}/autoprogrammer-api${NC}"
    exit 1
}
NODE_ENV=development npm run dev > "${PROJECT_ROOT}/api-debug.log" 2>&1 &
API_PID=$!
echo -e "${GREEN}API Gateway started with PID $API_PID${NC}"
sleep 3

# Start UI
echo -e "\n${YELLOW}Starting UI Service...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ui" || {
    echo -e "${RED}Error: UI directory not found at ${PROJECT_ROOT}/autoprogrammer-ui${NC}"
    exit 1
}
npm run dev > "${PROJECT_ROOT}/ui-debug.log" 2>&1 &
UI_PID=$!
echo -e "${GREEN}UI Service started with PID $UI_PID${NC}"
sleep 5

# Check if UI is running
if ! ps -p $UI_PID > /dev/null; then
    echo -e "${RED}UI Service failed to start. Check logs: ${PROJECT_ROOT}/ui-debug.log${NC}"
    tail -n 20 "${PROJECT_ROOT}/ui-debug.log"
else
    # Get the actual port being used
    if grep -q "Port 5173 is in use" "${PROJECT_ROOT}/ui-debug.log"; then
        UI_PORT=5174
    else
        UI_PORT=5173
    fi
    
    echo -e "${GREEN}UI Service is running on port $UI_PORT${NC}"
    
    echo -e "\n${BLUE}=========================================================${NC}"
    echo -e "${BLUE}                 Advanced UI Fix Complete                ${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "\nTo diagnose and fix the blank page issue:"
    echo -e "1. Open a new incognito/private window in Chrome"
    echo -e "2. Visit the advanced debug page: ${GREEN}http://localhost:$UI_PORT/debug-ui.html${NC}"
    echo -e "3. Use the diagnostic tools to identify issues"
    echo -e "4. Try the minimal React test page: ${GREEN}http://localhost:$UI_PORT/minimal-react.html${NC}"
    echo -e "5. Then try the main app again: ${GREEN}http://localhost:$UI_PORT/${NC}"
    echo -e "\nIf you still see a blank page, check the browser console for errors (F12)"
    echo -e "and review the logs:"
    echo -e "UI logs: ${GREEN}tail -f ui-debug.log${NC}"
    echo -e "API logs: ${GREEN}tail -f api-debug.log${NC}"
    echo -e "AI service logs: ${GREEN}tail -f ai-debug.log${NC}"
fi 