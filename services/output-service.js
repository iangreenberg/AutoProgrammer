/**
 * AutoProgrammer Output Service
 * 
 * This microservice is responsible for:
 * 1. Monitoring for output files
 * 2. Processing and normalizing outputs
 * 3. Making them available for the cursor-integration service
 */

const fs = require('fs');
const path = require('path');
const { promisify } = require('util');
const readFileAsync = promisify(fs.readFile);
const writeFileAsync = promisify(fs.writeFile);
const mkdirAsync = promisify(fs.mkdir);

// Load environment variables
require('dotenv').config();

// Constants
const OUTPUT_DIR = process.env.OUTPUT_DIR || './outputs';
const PROCESSED_DIR = path.join(OUTPUT_DIR, 'processed');
const SCAN_INTERVAL_MS = 5000; // Check every 5 seconds
const FILE_PATTERNS = [
  '*output*.txt',
  '*response*.txt',
  '*autoprogrammer*.txt',
  'cursor-prompt.txt'
];

// Ensure directories exist
async function ensureDirectories() {
  try {
    if (!fs.existsSync(OUTPUT_DIR)) {
      await mkdirAsync(OUTPUT_DIR, { recursive: true });
      console.log(`Created output directory: ${OUTPUT_DIR}`);
    }
    
    if (!fs.existsSync(PROCESSED_DIR)) {
      await mkdirAsync(PROCESSED_DIR, { recursive: true });
      console.log(`Created processed directory: ${PROCESSED_DIR}`);
    }
  } catch (error) {
    console.error('Error creating directories:', error);
  }
}

// Find output files
async function findOutputFiles() {
  // Platform-safe glob pattern implementation
  // This would normally use a glob module like 'glob' or 'fast-glob',
  // but for simplicity, we'll simulate it with direct fs methods
  const files = [];
  try {
    const desktopPath = path.join(process.env.HOME || process.env.USERPROFILE, 'Desktop');
    const paths = [OUTPUT_DIR, desktopPath, process.cwd()];
    
    for (const dir of paths) {
      if (fs.existsSync(dir)) {
        const dirFiles = fs.readdirSync(dir);
        for (const file of dirFiles) {
          if (file.endsWith('.txt') && 
            (file.includes('output') || file.includes('response') || 
             file.includes('autoprogrammer') || file === 'cursor-prompt.txt')) {
            files.push(path.join(dir, file));
          }
        }
      }
    }
  } catch (error) {
    console.error('Error finding output files:', error);
  }
  return files;
}

// Process an output file
async function processOutputFile(filePath) {
  try {
    const content = await readFileAsync(filePath, 'utf8');
    
    // Simple processing - normalize line endings and trim
    let processed = content.replace(/\r\n/g, '\n').trim();
    
    // Extract the filename without directory
    const fileName = path.basename(filePath);
    
    // Create a processed version with timestamp
    const timestamp = new Date().toISOString().replace(/:/g, '-');
    const processedFilePath = path.join(PROCESSED_DIR, `processed_${timestamp}_${fileName}`);
    
    // Write to the processed file
    await writeFileAsync(processedFilePath, processed);
    
    // Also write to the standard cursor output file for integration
    const cursorOutputPath = path.join(OUTPUT_DIR, 'cursor-output.txt');
    await writeFileAsync(cursorOutputPath, processed);
    
    console.log(`Processed file: ${fileName}`);
    return processedFilePath;
  } catch (error) {
    console.error(`Error processing file ${filePath}:`, error);
    return null;
  }
}

// Main monitoring function
async function monitorOutputs() {
  console.log('Output service started...');
  console.log(`Monitoring for outputs in: ${OUTPUT_DIR} and Desktop`);
  
  await ensureDirectories();
  
  // Track processed files to avoid reprocessing
  const processedFiles = new Set();
  
  // Main monitoring loop
  setInterval(async () => {
    try {
      const files = await findOutputFiles();
      
      for (const file of files) {
        // Skip already processed files
        if (processedFiles.has(file)) continue;
        
        // Get file stats
        const stats = fs.statSync(file);
        
        // Check if file was modified in the last 10 minutes
        const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
        if (stats.mtime >= tenMinutesAgo) {
          const processedPath = await processOutputFile(file);
          if (processedPath) {
            processedFiles.add(file);
            console.log(`New output detected and processed: ${file}`);
          }
        }
      }
      
      // Clean up processed files older than 30 minutes
      const now = Date.now();
      for (const file of processedFiles) {
        try {
          const stats = fs.statSync(file);
          const thirtyMinutesAgo = new Date(now - 30 * 60 * 1000);
          if (stats.mtime < thirtyMinutesAgo) {
            processedFiles.delete(file);
          }
        } catch (err) {
          // File may have been deleted or moved, remove from tracked set
          processedFiles.delete(file);
        }
      }
    } catch (error) {
      console.error('Error in monitoring loop:', error);
    }
  }, SCAN_INTERVAL_MS);
}

// Start the service
monitorOutputs().catch(err => {
  console.error('Fatal error in output service:', err);
  process.exit(1);
}); 