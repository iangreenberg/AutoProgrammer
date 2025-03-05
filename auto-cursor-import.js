/**
 * AutoProgrammer - Cursor Auto Import Service
 * 
 * This script monitors the AutoProgrammer output directory and makes new outputs available
 * to Cursor through multiple methods for maximum compatibility.
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const os = require('os');

// Configuration
const CONFIG = {
  checkInterval: 1000,  // Check every 1 second
  outputDir: path.join(__dirname, 'autoprogrammer-desktop', 'cursor-output'),
  cursorPromptFile: path.join(__dirname, 'cursor-prompt.txt'),
  watchFile: path.join(__dirname, '.cursor-watch.txt'),
  signalFile: path.join(__dirname, '.cursor-signals.json'),
  cursorsSpecialDir: path.join(__dirname, '.cursor-outputs'),
  cursorInputFile: path.join(__dirname, '.cursor-input.txt')
};

// Make sure directories exist
if (!fs.existsSync(CONFIG.outputDir)) {
  try {
    fs.mkdirSync(CONFIG.outputDir, { recursive: true });
  } catch (err) {
    console.error(`Failed to create output directory: ${err.message}`);
  }
}

if (!fs.existsSync(CONFIG.cursorsSpecialDir)) {
  try {
    fs.mkdirSync(CONFIG.cursorsSpecialDir, { recursive: true });
  } catch (err) {
    console.error(`Failed to create Cursor's special directory: ${err.message}`);
  }
}

// Keep track of processed outputs
const processedOutputs = new Set();

// Format the output in a way that's more recognizable to Cursor
function formatOutputForCursor(output) {
  let query = 'Unknown';
  let timestamp = new Date().toISOString();
  let content = output;
  
  // If this is a JSON object with metadata, extract more info
  if (typeof output === 'object' && output !== null) {
    query = output.query || query;
    timestamp = output.timestamp || timestamp;
    content = output.content || JSON.stringify(output, null, 2);
  }
  
  return `
===== AUTOPROGRAMMER OUTPUT =====
QUERY: ${query}
TIMESTAMP: ${timestamp}

${content}
================================
`;
}

// Make the output available to Cursor through multiple methods
function makeOutputAvailableToCursor(formattedOutput) {
  try {
    // Method 1: Save to the main cursor-prompt.txt file
    fs.writeFileSync(CONFIG.cursorPromptFile, formattedOutput);
    
    // Method 2: Write to a special cursor watch file
    fs.writeFileSync(CONFIG.watchFile, formattedOutput);
    
    // Method 3: Create a unique timestamped file for Cursor to find
    const timestamp = Date.now();
    const timestampedFile = path.join(__dirname, `.cursor-output-${timestamp}.txt`);
    fs.writeFileSync(timestampedFile, formattedOutput);
    
    // Method 4: Write to a special cursor input file
    fs.writeFileSync(CONFIG.cursorInputFile, formattedOutput);
    
    // Method 5: Try to copy to clipboard
    try {
      const encodedOutput = formattedOutput.replace(/"/g, '\\"').replace(/\n/g, '\\n');
      
      if (os.platform() === 'darwin') {
        // macOS
        exec(`echo "${encodedOutput}" | pbcopy`);
      } else if (os.platform() === 'win32') {
        // Windows
        exec(`echo "${encodedOutput}" | clip`);
      } else {
        // Linux
        exec(`echo "${encodedOutput}" | xclip -selection clipboard`);
      }
    } catch (clipboardError) {
      // Ignore clipboard errors
    }
    
    // Method 6: Create a special signals file that other processes can monitor
    fs.writeFileSync(CONFIG.signalFile, JSON.stringify({
      hasNewOutput: true,
      timestamp: Date.now(),
      outputPath: timestampedFile
    }));
    
    // Success message
    console.log(`✅ Output formatted and made available to Cursor [${new Date().toLocaleTimeString()}]`);
    
  } catch (error) {
    console.error(`Failed to make output available to Cursor: ${error.message}`);
  }
}

// Check for new outputs in the AutoProgrammer output directory
function checkForNewOutputs() {
  try {
    // Check if the output directory exists
    if (!fs.existsSync(CONFIG.outputDir)) {
      return;
    }
    
    // Check for latest-output.json
    const latestOutputFile = path.join(CONFIG.outputDir, 'latest-output.json');
    if (fs.existsSync(latestOutputFile)) {
      try {
        const stats = fs.statSync(latestOutputFile);
        const fileKey = `${latestOutputFile}-${stats.mtimeMs}`;
        
        if (!processedOutputs.has(fileKey)) {
          // Read and parse the metadata file
          const metadata = JSON.parse(fs.readFileSync(latestOutputFile, 'utf8'));
          const outputFile = path.join(CONFIG.outputDir, metadata.filename);
          
          if (fs.existsSync(outputFile)) {
            // Read the actual output content
            const content = fs.readFileSync(outputFile, 'utf8');
            
            // Create a combined output object
            const outputObj = {
              query: metadata.query,
              timestamp: metadata.timestamp,
              content: content
            };
            
            // Format and make available to Cursor
            const formattedOutput = formatOutputForCursor(outputObj);
            makeOutputAvailableToCursor(formattedOutput);
            
            // Mark as processed
            processedOutputs.add(fileKey);
          }
        }
      } catch (error) {
        console.error(`Error processing latest output: ${error.message}`);
      }
    }
    
    // Also check for any direct output files in the output directory
    const files = fs.readdirSync(CONFIG.outputDir);
    for (const file of files) {
      if (file.endsWith('.txt') && !file.startsWith('.')) {
        const filePath = path.join(CONFIG.outputDir, file);
        const stats = fs.statSync(filePath);
        const fileKey = `${filePath}-${stats.mtimeMs}`;
        
        if (!processedOutputs.has(fileKey)) {
          const content = fs.readFileSync(filePath, 'utf8');
          
          // Format and make available to Cursor
          const formattedOutput = formatOutputForCursor(content);
          makeOutputAvailableToCursor(formattedOutput);
          
          // Mark as processed
          processedOutputs.add(fileKey);
        }
      }
    }
    
  } catch (error) {
    console.error(`Error checking for new outputs: ${error.message}`);
  }
}

// Main monitoring loop
console.log("Starting AutoProgrammer Cursor Auto-Import Service...");
console.log(`Monitoring directory: ${CONFIG.outputDir}`);
console.log("Any new outputs will be automatically formatted and made available to Cursor");

// Initial check
checkForNewOutputs();

// Set up interval to check for new outputs
setInterval(checkForNewOutputs, CONFIG.checkInterval);

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log("Auto-Import service is shutting down...");
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log("Auto-Import service is shutting down...");
  process.exit(0);
}); 