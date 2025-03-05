/**
 * Cursor Import Script
 * 
 * This script reads the latest AutoProgrammer output and formats it for Cursor.
 * It's designed to be run directly by Cursor to import the latest output.
 */

const fs = require('fs');
const path = require('path');

// Path to the cursor prompt file
const cursorPromptFile = path.join(__dirname, 'cursor-prompt.txt');

// Check if the file exists
if (!fs.existsSync(cursorPromptFile)) {
  console.log('No AutoProgrammer output found. Please run AutoProgrammer and generate a response first.');
  process.exit(1);
}

// Read the file
const content = fs.readFileSync(cursorPromptFile, 'utf8');

// Print the content (Cursor will capture this output)
console.log(content);

// Exit with success
process.exit(0); 