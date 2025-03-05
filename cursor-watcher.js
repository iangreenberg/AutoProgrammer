/**
 * Cursor Watcher
 * 
 * This script monitors for new outputs from AutoProgrammer and inserts them into Cursor.
 * It uses multiple methods to ensure the output appears in Cursor correctly.
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

// Configuration
const CONFIG = {
  checkInterval: 1000,        // Check every 1 second
  timeout: 30 * 60 * 1000,    // Run for 30 minutes
  outputFiles: [
    '.cursor-input.txt',
    '.cursor-watch.txt', 
    'cursor-prompt.txt'
  ],
  signalsFile: '.cursor-signals.json'
};

// Base directory is where this script is located
const baseDir = __dirname;

// Keep track of files we've already processed
const processedFiles = new Set();

// Find all special timestamped output files
function findTimestampedOutputFiles() {
  try {
    const files = fs.readdirSync(baseDir)
      .filter(file => file.startsWith('.cursor-output-') && file.endsWith('.txt'))
      .map(file => path.join(baseDir, file));
    return files;
  } catch (error) {
    console.error(`Error finding timestamped files: ${error.message}`);
    return [];
  }
}

// Aggressively output the content to ensure Cursor captures it
function outputToCursor(content) {
  try {
    // Method 1: Direct console output
    console.log(`\n----- AUTOPROGRAMMER OUTPUT -----\n${content}\n------------------------------\n`);
    
    // Method 2: Write directly to stdout to avoid buffering
    process.stdout.write(`\n${content}\n`);
    
    // Method 3: Try to copy to clipboard on various platforms
    try {
      // macOS
      exec(`echo "${content.replace(/"/g, '\\"')}" | pbcopy`, (error) => {
        if (error) {
          // Try Windows clip.exe
          exec(`echo "${content.replace(/"/g, '\\"')}" | clip`, (err) => {
            if (err) {
              // Try xclip for Linux
              exec(`echo "${content.replace(/"/g, '\\"')}" | xclip -selection clipboard`);
            }
          });
        }
      });
    } catch (clipboardError) {
      // Ignore clipboard errors
    }
    
    // Method 4: Create a special file for Cursor to find
    const specialOutputFile = path.join(baseDir, '.cursor-special-output.txt');
    fs.writeFileSync(specialOutputFile, content);
    
    // Method 5: Delayed output (sometimes helps with timing issues)
    setTimeout(() => {
      console.log(`\n${content}\n`);
    }, 500);
    
  } catch (error) {
    console.error(`Error outputting to Cursor: ${error.message}`);
  }
}

// Check for new outputs from AutoProgrammer
function checkForNewOutput() {
  try {
    // First check the signals file
    const signalsFile = path.join(baseDir, CONFIG.signalsFile);
    if (fs.existsSync(signalsFile)) {
      try {
        const signalData = JSON.parse(fs.readFileSync(signalsFile, 'utf8'));
        if (signalData.hasNewOutput && fs.existsSync(signalData.outputPath)) {
          const outputPath = signalData.outputPath;
          if (!processedFiles.has(outputPath)) {
            const content = fs.readFileSync(outputPath, 'utf8');
            outputToCursor(content);
            processedFiles.add(outputPath);
            return true;
          }
        }
      } catch (error) {
        // Ignore errors with signal file
      }
    }
    
    // Check for timestamped output files
    const timestampedFiles = findTimestampedOutputFiles();
    for (const file of timestampedFiles) {
      if (!processedFiles.has(file)) {
        const content = fs.readFileSync(file, 'utf8');
        outputToCursor(content);
        processedFiles.add(file);
        return true;
      }
    }
    
    // Check all configured output files
    for (const file of CONFIG.outputFiles) {
      const filePath = path.join(baseDir, file);
      if (fs.existsSync(filePath)) {
        const stats = fs.statSync(filePath);
        const fileKey = `${filePath}-${stats.mtimeMs}`;
        
        if (!processedFiles.has(fileKey)) {
          const content = fs.readFileSync(filePath, 'utf8');
          outputToCursor(content);
          processedFiles.add(fileKey);
          return true;
        }
      }
    }
    
    // Check for JSON metadata file
    const jsonMetadataFile = path.join(baseDir, 'autoprogrammer-desktop', 'cursor-output', 'latest-output.json');
    if (fs.existsSync(jsonMetadataFile)) {
      const stats = fs.statSync(jsonMetadataFile);
      const fileKey = `${jsonMetadataFile}-${stats.mtimeMs}`;
      
      if (!processedFiles.has(fileKey)) {
        try {
          const metadata = JSON.parse(fs.readFileSync(jsonMetadataFile, 'utf8'));
          const outputFile = path.join(path.dirname(jsonMetadataFile), metadata.filename);
          
          if (fs.existsSync(outputFile)) {
            const content = fs.readFileSync(outputFile, 'utf8');
            const formattedOutput = `
===== AUTOPROGRAMMER OUTPUT =====
QUERY: ${metadata.query}
TIMESTAMP: ${metadata.timestamp}

${content}
================================
`;
            outputToCursor(formattedOutput);
            processedFiles.add(fileKey);
            return true;
          }
        } catch (error) {
          // Ignore JSON parsing errors
        }
      }
    }
    
    return false;
  } catch (error) {
    console.error(`Error checking for new output: ${error.message}`);
    return false;
  }
}

// Start the watcher
console.log("Starting Cursor watcher...");
console.log(`Will run for ${CONFIG.timeout / 60000} minutes and check every ${CONFIG.checkInterval / 1000} seconds`);
console.log("Monitoring for AutoProgrammer outputs...");

// Initial check
checkForNewOutput();

// Set up the interval to check for new outputs
const intervalId = setInterval(checkForNewOutput, CONFIG.checkInterval);

// Set up a timeout to stop the watcher after the configured time
setTimeout(() => {
  clearInterval(intervalId);
  console.log(`\nCursor watcher stopped after ${CONFIG.timeout / 60000} minutes.`);
  console.log("To restart, run './start-cursor-watcher.sh'");
  process.exit(0);
}, CONFIG.timeout);

// Handle script termination
process.on('SIGINT', () => {
  clearInterval(intervalId);
  console.log("\nCursor watcher stopped.");
  process.exit(0);
});

process.on('SIGTERM', () => {
  clearInterval(intervalId);
  console.log("\nCursor watcher stopped.");
  process.exit(0);
}); 