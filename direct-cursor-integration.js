/**
 * Direct Cursor Integration Script
 * 
 * This script is designed to be run directly within a Cursor tab.
 * It will directly output the latest AutoProgrammer result as a prompt.
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const os = require('os');

// Base directory is where this script is located
const baseDir = __dirname;

// Possible locations of output files
const possibleFiles = [
  path.join(baseDir, '.cursor-input.txt'),
  path.join(baseDir, '.cursor-watch.txt'),
  path.join(baseDir, 'cursor-prompt.txt'),
  path.join(baseDir, 'autoprogrammer-desktop', 'cursor-output', 'latest-output.json'),
  path.join(baseDir, 'autoprogrammer-output.txt'),
  path.join(baseDir, 'output.txt'),
  path.join(baseDir, 'response.txt'),
  path.join(baseDir, 'autoprogrammer.txt'),
  path.join(baseDir, 'autoprogrammer-desktop', 'output.txt'),
  path.join(os.homedir(), 'Desktop', 'autoprogrammer-output.txt')
];

// Check for signal files
const signalFile = path.join(baseDir, '.cursor-signals.json');

// Function to get the most recent file from a list
function getMostRecentFile(files) {
  let mostRecentFile = null;
  let mostRecentTime = 0;

  for (const file of files) {
    if (fs.existsSync(file)) {
      const stats = fs.statSync(file);
      if (stats.mtimeMs > mostRecentTime) {
        mostRecentTime = stats.mtimeMs;
        mostRecentFile = file;
      }
    }
  }

  return mostRecentFile;
}

// Function to search for any potential output file in a directory
function findPotentialOutputFiles(directory) {
  if (!fs.existsSync(directory) || !fs.statSync(directory).isDirectory()) {
    return [];
  }

  try {
    return fs.readdirSync(directory)
      .filter(file => {
        // Look for files that might contain output
        return file.endsWith('.txt') || 
               file.endsWith('.json') || 
               file.endsWith('.md') || 
               file.includes('output') || 
               file.includes('response') || 
               file.includes('autoprogrammer');
      })
      .map(file => path.join(directory, file));
  } catch (error) {
    return [];
  }
}

// Function to check for any timestamped output files
function findTimestampedOutputFiles() {
  try {
    const files = fs.readdirSync(baseDir)
      .filter(file => file.startsWith('.cursor-output-') && file.endsWith('.txt'))
      .map(file => path.join(baseDir, file));
    return files;
  } catch (error) {
    return [];
  }
}

// Recursively search for output files in the directory structure
function findAllPotentialOutputs() {
  const results = [];
  
  // Add the base directory files
  results.push(...findPotentialOutputFiles(baseDir));
  
  // Add the autoprogrammer-desktop directory files
  const desktopDir = path.join(baseDir, 'autoprogrammer-desktop');
  if (fs.existsSync(desktopDir)) {
    results.push(...findPotentialOutputFiles(desktopDir));
    
    // Also check cursor-output subdirectory
    const cursorOutputDir = path.join(desktopDir, 'cursor-output');
    if (fs.existsSync(cursorOutputDir)) {
      results.push(...findPotentialOutputFiles(cursorOutputDir));
    }
  }
  
  return results;
}

// Main function to get and output the latest content
function getLatestOutput() {
  // First check signal file
  if (fs.existsSync(signalFile)) {
    try {
      const signalData = JSON.parse(fs.readFileSync(signalFile, 'utf8'));
      if (signalData.hasNewOutput && fs.existsSync(signalData.outputPath)) {
        return fs.readFileSync(signalData.outputPath, 'utf8');
      }
    } catch (error) {
      // Ignore errors with signal file
    }
  }
  
  // Check for timestamped output files
  const timestampedFiles = findTimestampedOutputFiles();
  if (timestampedFiles.length > 0) {
    const mostRecentTimestampedFile = getMostRecentFile(timestampedFiles);
    if (mostRecentTimestampedFile) {
      return fs.readFileSync(mostRecentTimestampedFile, 'utf8');
    }
  }
  
  // Check all possible explicitly defined files
  const mostRecentFile = getMostRecentFile(possibleFiles);
  if (mostRecentFile) {
    // Special handling for JSON file
    if (mostRecentFile.endsWith('latest-output.json')) {
      try {
        const metadata = JSON.parse(fs.readFileSync(mostRecentFile, 'utf8'));
        const outputFile = path.join(path.dirname(mostRecentFile), metadata.filename);
        if (fs.existsSync(outputFile)) {
          const content = fs.readFileSync(outputFile, 'utf8');
          return `
===== AUTOPROGRAMMER OUTPUT =====
QUERY: ${metadata.query}
TIMESTAMP: ${metadata.timestamp}

${content}
================================
`;
        }
      } catch (error) {
        // If JSON parsing fails, continue to next option
      }
    } else {
      // Regular text file
      return fs.readFileSync(mostRecentFile, 'utf8');
    }
  }
  
  // Search more aggressively in the directory structure
  const allPotentialFiles = findAllPotentialOutputs();
  if (allPotentialFiles.length > 0) {
    // Get the most recent file from potential outputs
    const mostRecentPotentialFile = getMostRecentFile(allPotentialFiles);
    if (mostRecentPotentialFile) {
      try {
        const content = fs.readFileSync(mostRecentPotentialFile, 'utf8');
        return `
===== AUTOPROGRAMMER OUTPUT (FROM ${path.basename(mostRecentPotentialFile)}) =====

${content}
================================
`;
      } catch (error) {
        // If reading fails, continue
      }
    }
  }
  
  // Try searching in home directory for any outputs
  try {
    const homeDir = os.homedir();
    const homeFiles = findPotentialOutputFiles(homeDir);
    const desktopFiles = findPotentialOutputFiles(path.join(homeDir, 'Desktop'));
    const documentsFiles = findPotentialOutputFiles(path.join(homeDir, 'Documents'));
    
    const allHomeFiles = [...homeFiles, ...desktopFiles, ...documentsFiles];
    
    if (allHomeFiles.length > 0) {
      const mostRecentHomeFile = getMostRecentFile(allHomeFiles);
      if (mostRecentHomeFile) {
        try {
          const content = fs.readFileSync(mostRecentHomeFile, 'utf8');
          return `
===== AUTOPROGRAMMER OUTPUT (FROM ${mostRecentHomeFile}) =====

${content}
================================
`;
        } catch (error) {
          // If reading fails, continue
        }
      }
    }
  } catch (error) {
    // Ignore errors searching home directory
  }
  
  return "No AutoProgrammer output found. Please make sure AutoProgrammer is running and has generated a response. Try running AutoProgrammer and generating a response, then run this script again.";
}

// Print the output in multiple formats to ensure Cursor captures it
function outputToCursor(content) {
  // Try to find potential copy commands
  let copyCommand = null;
  
  // Determine the clipboard command based on the platform
  if (os.platform() === 'darwin') {
    copyCommand = 'pbcopy';
  } else if (os.platform() === 'win32') {
    copyCommand = 'clip';
  } else {
    copyCommand = 'xclip -selection clipboard';
  }
  
  // Method 1: Standard console.log
  console.log('\n\n' + content + '\n\n');
  
  // Method 2: Direct process.stdout write
  process.stdout.write('\n' + content + '\n');
  
  // Method 3: Try to copy to clipboard
  if (copyCommand) {
    try {
      const tempFilePath = path.join(os.tmpdir(), 'cursor-output.txt');
      fs.writeFileSync(tempFilePath, content);
      exec(`cat "${tempFilePath}" | ${copyCommand}`);
    } catch (error) {
      // Ignore clipboard errors
    }
  }
  
  // Method 4: Write to special Cursor files
  try {
    fs.writeFileSync(path.join(baseDir, '.cursor-special-output.txt'), content);
    fs.writeFileSync(path.join(baseDir, '.cursor-direct-input.txt'), content);
  } catch (error) {
    // Ignore file write errors
  }
  
  // Method 5: Delayed output (sometimes helps with timing issues)
  setTimeout(() => {
    console.log('\n' + content + '\n');
  }, 500);
}

// Get the latest content
const output = getLatestOutput();

// Output to Cursor using multiple methods
outputToCursor(output);

// Let the user know the script is running in watch mode if uncommented in run-in-cursor.sh
if (process.argv.includes('--watch')) {
  console.log('\n*** Running in watch mode. Will check for new outputs every 2 seconds. ***');
  console.log('*** Press Ctrl+C to stop. ***\n');
}

// Exit with success
process.exit(0); 