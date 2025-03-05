/**
 * AutoProgrammer - Output Detector
 * 
 * This script runs continuously and monitors for any new file creations or modifications
 * that might be AutoProgrammer outputs, then makes them immediately available to Cursor.
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const os = require('os');
const chokidar = require('chokidar'); // This requires installation: npm install chokidar

// Configuration
const CONFIG = {
  // Directories to watch
  watchDirs: [
    __dirname,
    path.join(__dirname, 'autoprogrammer-desktop'),
    path.join(__dirname, 'autoprogrammer-desktop', 'cursor-output'),
    os.homedir(),
    path.join(os.homedir(), 'Desktop'),
    path.join(os.homedir(), 'Documents')
  ],
  // Files to create for Cursor
  outputFiles: {
    main: path.join(__dirname, 'cursor-prompt.txt'),
    special: path.join(__dirname, '.cursor-special-output.txt'),
    direct: path.join(__dirname, '.cursor-direct-input.txt'),
    watch: path.join(__dirname, '.cursor-watch.txt'),
    signals: path.join(__dirname, '.cursor-signals.json')
  },
  // File patterns to match
  patterns: [
    '**/*output*.txt',
    '**/*output*.json',
    '**/*response*.txt',
    '**/*autoprogrammer*.txt',
    '**/*.md'
  ],
  // Ignore patterns
  ignorePatterns: [
    'node_modules/**',
    '.git/**',
    '**/*.log'
  ]
};

// Processed files tracker
const processedFiles = new Map();

// Format output for Cursor
function formatOutputForCursor(content, sourcePath = 'unknown') {
  return `
===== AUTOPROGRAMMER OUTPUT =====
SOURCE: ${sourcePath}
DETECTED: ${new Date().toLocaleTimeString()}

${content}
================================
`;
}

// Make the file available to Cursor through multiple methods
function makeAvailableToCursor(content, sourcePath) {
  try {
    const formattedOutput = formatOutputForCursor(content, sourcePath);
    
    // Write to all output files
    for (const [key, filePath] of Object.entries(CONFIG.outputFiles)) {
      if (key !== 'signals') {
        fs.writeFileSync(filePath, formattedOutput);
      }
    }
    
    // Create a unique timestamped file
    const timestamp = Date.now();
    const timestampedFile = path.join(__dirname, `.cursor-output-${timestamp}.txt`);
    fs.writeFileSync(timestampedFile, formattedOutput);
    
    // Create a signals file
    fs.writeFileSync(CONFIG.outputFiles.signals, JSON.stringify({
      hasNewOutput: true,
      timestamp: timestamp,
      outputPath: timestampedFile,
      sourcePath: sourcePath
    }));
    
    // Try to copy to clipboard
    try {
      const tempFilePath = path.join(os.tmpdir(), 'cursor-output.txt');
      fs.writeFileSync(tempFilePath, formattedOutput);
      
      if (os.platform() === 'darwin') {
        exec(`cat "${tempFilePath}" | pbcopy`);
      } else if (os.platform() === 'win32') {
        exec(`cat "${tempFilePath}" | clip`);
      } else {
        exec(`cat "${tempFilePath}" | xclip -selection clipboard`);
      }
    } catch (error) {
      // Ignore clipboard errors
    }
    
    // Try to output directly to console
    console.log('\n\n' + formattedOutput + '\n\n');
    
    console.log(`✅ Output detected from ${path.basename(sourcePath)} and made available to Cursor!`);
    
  } catch (error) {
    console.error(`Error making file available to Cursor: ${error.message}`);
  }
}

// Process a file when it changes
function processFile(filePath) {
  try {
    // Get file stats
    const stats = fs.statSync(filePath);
    const key = `${filePath}-${stats.mtimeMs}`;
    
    // Skip if already processed this exact version
    if (processedFiles.has(key)) {
      return;
    }
    
    // Read the file
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Skip if content is too short (likely not an output)
    if (content.length < 10) {
      return;
    }
    
    // Skip if content doesn't look like a meaningful output
    // This helps avoid processing files that aren't actually outputs
    if (!content.includes(' ') || !content.includes('\n')) {
      return;
    }
    
    // Special handling for JSON files
    if (filePath.endsWith('.json')) {
      try {
        const jsonData = JSON.parse(content);
        
        // If this is a metadata file with a reference to another file
        if (jsonData.filename && typeof jsonData.filename === 'string') {
          const outputFile = path.join(path.dirname(filePath), jsonData.filename);
          if (fs.existsSync(outputFile)) {
            const outputContent = fs.readFileSync(outputFile, 'utf8');
            makeAvailableToCursor(outputContent, outputFile);
            processedFiles.set(key, true);
          }
        } else {
          // Use the JSON content directly
          const prettyJson = JSON.stringify(jsonData, null, 2);
          makeAvailableToCursor(prettyJson, filePath);
          processedFiles.set(key, true);
        }
      } catch (error) {
        // Not valid JSON, treat as text
        makeAvailableToCursor(content, filePath);
        processedFiles.set(key, true);
      }
    } else {
      // Regular text file
      makeAvailableToCursor(content, filePath);
      processedFiles.set(key, true);
    }
    
  } catch (error) {
    console.error(`Error processing file ${filePath}: ${error.message}`);
  }
}

// Set up the file watcher
console.log("Starting AutoProgrammer Output Detector...");

// Create a watcher instance
const watcher = chokidar.watch(CONFIG.patterns, {
  ignored: CONFIG.ignorePatterns,
  cwd: __dirname,
  persistent: true,
  ignoreInitial: false, // Also process existing files
  awaitWriteFinish: {
    stabilityThreshold: 1000, // Wait for files to stabilize for 1s
    pollInterval: 100
  }
});

// Add all watch directories
CONFIG.watchDirs.forEach(dir => {
  if (fs.existsSync(dir)) {
    watcher.add(path.join(dir, '**/*.txt'));
    watcher.add(path.join(dir, '**/*.json'));
    watcher.add(path.join(dir, '**/*.md'));
  }
});

// Set up event handlers
watcher
  .on('add', filePath => {
    console.log(`File added: ${filePath}`);
    processFile(path.resolve(__dirname, filePath));
  })
  .on('change', filePath => {
    console.log(`File changed: ${filePath}`);
    processFile(path.resolve(__dirname, filePath));
  })
  .on('ready', () => {
    console.log('Initial scan complete. Watching for new or changed files...');
    console.log('Any new outputs from AutoProgrammer will be automatically made available to Cursor.');
  })
  .on('error', error => {
    console.error(`Error: ${error}`);
  });

// Handle script termination
process.on('SIGINT', () => {
  console.log('Stopping detector...');
  watcher.close().then(() => process.exit(0));
});

// Keep the script running
console.log('Output detector is running. Press Ctrl+C to stop.'); 