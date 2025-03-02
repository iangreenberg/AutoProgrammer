#!/bin/bash

echo "=========================================================="
echo "        Fixing UI Blank Page Issue"
echo "=========================================================="

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set up the project root for reference
PROJECT_ROOT="$(pwd)"

# First, stop the UI service
echo -e "${YELLOW}Stopping UI Service...${NC}"
pkill -f "node.*vite" || true
sleep 2

# Force kill any processes on UI ports
for port in 5173 5174; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo -e "Killing process $pid using port $port"
        kill -9 $pid 2>/dev/null || true
        sleep 1
    fi
done

# Verify ports are free
for port in 5173 5174; do
    if lsof -i:$port &>/dev/null; then
        echo -e "${RED}Port $port is still in use. Please check manually with 'lsof -i:$port'${NC}"
    else
        echo -e "${GREEN}Port $port is free${NC}"
    fi
done

# Change to UI directory
echo -e "\n${YELLOW}Updating UI configuration...${NC}"
cd "${PROJECT_ROOT}/autoprogrammer-ui" || {
    echo -e "${RED}Error: UI directory not found at ${PROJECT_ROOT}/autoprogrammer-ui${NC}"
    exit 1
}

# Clean Vite cache
echo -e "Cleaning Vite cache..."
rm -rf node_modules/.vite
rm -rf node_modules/.cache

# Create .env file with proper API URL
echo -e "Creating .env file with API Gateway URL..."
cat > ".env" << EOL
VITE_API_GATEWAY_URL=http://localhost:4000
EOL
echo -e "${GREEN}API Gateway URL configured${NC}"

# Create a browser reset script
echo -e "Creating browser cache reset HTML..."
mkdir -p public
cat > "public/reset-browser.html" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Browser Reset</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
        }
        .success {
            color: green;
            font-weight: bold;
        }
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
        code {
            background-color: #f5f5f5;
            padding: 2px 5px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <h1>Browser Cache Reset</h1>
    <div class="container">
        <h2>Cache Reset Tools</h2>
        <p>This page helps reset your browser's cache to fix blank page issues with the AutoProgrammer UI.</p>
        
        <div>
            <h3>Step 1: Clear LocalStorage</h3>
            <p>Click the button below to clear localStorage for this domain:</p>
            <button onclick="clearLocalStorage()">Clear LocalStorage</button>
            <p id="localStorageResult"></p>
        </div>
        
        <div>
            <h3>Step 2: Hard Refresh</h3>
            <p>Perform a hard refresh with one of these keyboard shortcuts:</p>
            <ul>
                <li><strong>Mac:</strong> Command + Shift + R</li>
                <li><strong>Windows/Linux:</strong> Ctrl + Shift + R</li>
            </ul>
        </div>
        
        <div>
            <h3>Step 3: Check Console</h3>
            <p>Open Developer Tools and check for errors in the Console tab:</p>
            <ul>
                <li><strong>Mac:</strong> Command + Option + J</li>
                <li><strong>Windows/Linux:</strong> Ctrl + Shift + J</li>
            </ul>
        </div>
        
        <div>
            <h3>Step 4: Return to UI</h3>
            <p>After completing the steps above, return to the main UI:</p>
            <button onclick="goToMainUI()">Go to Main UI</button>
        </div>
    </div>

    <script>
        function clearLocalStorage() {
            try {
                localStorage.clear();
                document.getElementById('localStorageResult').innerHTML = 
                    '<span class="success">✓ LocalStorage cleared successfully!</span>';
            } catch (e) {
                document.getElementById('localStorageResult').innerHTML = 
                    '<span style="color:red">Error clearing localStorage: ' + e.message + '</span>';
            }
        }
        
        function goToMainUI() {
            window.location.href = '/';
        }
        
        // Print browser info to help with debugging
        document.addEventListener('DOMContentLoaded', function() {
            console.log('Browser: ' + navigator.userAgent);
            console.log('Accessing from: ' + window.location.href);
        });
    </script>
</body>
</html>
EOL
echo -e "${GREEN}Browser reset page created${NC}"

# Create a test page that includes React-specific debugging
echo -e "Creating UI test page..."
cat > "public/test-ui.html" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UI Test Page</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
        }
        .success {
            color: green;
            font-weight: bold;
        }
        .error {
            color: red;
            font-weight: bold;
        }
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
        }
    </style>
    <script src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
</head>
<body>
    <h1>UI Test Page</h1>
    <div class="container">
        <h2>React Availability Test</h2>
        <div id="react-test-result"></div>
        
        <h2>API Gateway Connection Test</h2>
        <button onclick="testAPIConnection()">Test API Connection</button>
        <div id="api-test-result"></div>
        
        <h2>DOM Tree Test</h2>
        <div id="dom-test"></div>
        
        <h2>Return to Application</h2>
        <p>After confirming the tests above, you can return to the main application:</p>
        <button onclick="window.location.href='/'">Go to Main UI</button>
    </div>

    <script>
        // Test React availability
        function testReact() {
            const result = document.getElementById('react-test-result');
            try {
                if (typeof React !== 'undefined' && typeof ReactDOM !== 'undefined') {
                    const element = React.createElement('div', {className: 'success'}, 
                        '✓ React is available (version ' + React.version + ')');
                    ReactDOM.render(element, result);
                } else {
                    result.innerHTML = '<div class="error">✗ React is not available</div>';
                }
            } catch (e) {
                result.innerHTML = '<div class="error">✗ Error testing React: ' + e.message + '</div>';
            }
        }
        
        // Test API Gateway connection
        function testAPIConnection() {
            const result = document.getElementById('api-test-result');
            result.innerHTML = '<div>Testing connection to API Gateway...</div>';
            
            fetch('http://localhost:4000/health')
                .then(response => {
                    if (response.ok) {
                        return response.json().catch(() => 'OK');
                    }
                    throw new Error('Network response was not ok: ' + response.status);
                })
                .then(data => {
                    result.innerHTML = '<div class="success">✓ API Gateway is accessible</div>';
                    result.innerHTML += '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                })
                .catch(error => {
                    result.innerHTML = '<div class="error">✗ Error accessing API Gateway: ' + error.message + '</div>';
                    result.innerHTML += '<p>Make sure the API Gateway is running on http://localhost:4000</p>';
                });
        }
        
        // Create a simple DOM tree to test rendering
        function testDOM() {
            const container = document.getElementById('dom-test');
            const testDiv = document.createElement('div');
            testDiv.style.border = '1px solid #ddd';
            testDiv.style.padding = '10px';
            testDiv.style.marginTop = '10px';
            
            const heading = document.createElement('h3');
            heading.textContent = 'DOM Test Result';
            
            const paragraph = document.createElement('p');
            paragraph.className = 'success';
            paragraph.textContent = '✓ DOM manipulation is working correctly';
            
            testDiv.appendChild(heading);
            testDiv.appendChild(paragraph);
            container.appendChild(testDiv);
        }
        
        // Run all tests when page loads
        document.addEventListener('DOMContentLoaded', function() {
            testReact();
            testDOM();
        });
    </script>
</body>
</html>
EOL
echo -e "${GREEN}UI test page created${NC}"

# Restart UI
echo -e "\n${YELLOW}Starting UI Service...${NC}"
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
    echo -e "${BLUE}                 UI Has Been Restarted                   ${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "\nTo fix the blank page issue:"
    echo -e "1. Open an incognito/private window in your browser"
    echo -e "2. Visit the browser reset page: ${GREEN}http://localhost:$UI_PORT/reset-browser.html${NC}"
    echo -e "3. Follow the instructions to clear cache and refresh"
    echo -e "4. Visit the test page: ${GREEN}http://localhost:$UI_PORT/test-ui.html${NC}"
    echo -e "5. Then try the main app again: ${GREEN}http://localhost:$UI_PORT/${NC}"
    echo -e "\nIf you still see a blank page, check the browser console for errors (F12)"
    echo -e "and review the UI logs: ${GREEN}tail -f ui-debug.log${NC}"
fi 