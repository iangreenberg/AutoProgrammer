/**
 * Response Formatter Utility
 * Formats raw DeepSeek API responses into structured development strategies
 */

/**
 * Format the response from DeepSeek API into a structured format
 * @param {string} rawResponse - The raw response from DeepSeek API
 * @param {string} originalQuery - The original query for context
 * @returns {string} - Formatted response with proper structure
 */
export function formatResponse(rawResponse, originalQuery) {
  // If no response, provide an error message
  if (!rawResponse) {
    return `## Error\nUnable to generate a response for your query: "${originalQuery}".`;
  }
  
  try {
    // Check if response already has proper markdown structure
    const hasStructure = 
      (rawResponse.includes('# ') || rawResponse.includes('## ')) && 
      (rawResponse.includes('Architecture') || rawResponse.includes('Best Practices'));
    
    // If it has proper structure, just ensure consistent formatting
    if (hasStructure) {
      return ensureConsistentFormatting(rawResponse, originalQuery);
    }
    
    // If not structured, create structure
    return createStructuredResponse(rawResponse, originalQuery);
  } catch (error) {
    console.error('Error formatting response:', error);
    // Return the original response if formatting fails
    return rawResponse;
  }
}

/**
 * Ensure consistent formatting for already structured responses
 * @param {string} response - The response to format
 * @param {string} query - The original query
 * @returns {string} - Consistently formatted response
 */
function ensureConsistentFormatting(response, query) {
  // Add title if missing
  if (!response.startsWith('# ')) {
    response = `# Software Development Strategy for: ${query}\n\n${response}`;
  }
  
  // Ensure section headers are properly formatted
  const requiredSections = [
    { title: 'Software Architecture', content: 'Components, design patterns, and technologies' },
    { title: 'Best Practices', content: 'Coding standards, security, and optimization' },
    { title: 'Implementation Strategy', content: 'Step-by-step approach to building the solution' },
    { title: 'Cursor-Optimized Prompts', content: 'Specific prompts for AI coding assistants' }
  ];
  
  // Check if each section exists and add placeholder if missing
  for (const section of requiredSections) {
    const sectionRegex = new RegExp(`## \\d*\\.?\\s*${section.title}|## ${section.title}`, 'i');
    if (!sectionRegex.test(response)) {
      response += `\n\n## ${section.title}\n${section.content}`;
    }
  }
  
  return response;
}

/**
 * Create a structured response from unstructured content
 * @param {string} content - The unstructured content
 * @param {string} query - The original query
 * @returns {string} - A well-structured response
 */
function createStructuredResponse(content, query) {
  return `# Software Development Strategy for: ${query}

## 1. Software Architecture

${extractArchitectureInfo(content)}

## 2. Best Practices

${extractBestPractices(content)}

## 3. Implementation Strategy

${extractImplementationStrategy(content)}

## 4. Cursor-Optimized Prompts

${extractCursorPrompts(content, query)}

---

*Note: This response has been automatically structured for clarity.*`;
}

/**
 * Extract architecture information from the content
 * @param {string} content - The content to extract from
 * @returns {string} - Extracted architecture info
 */
function extractArchitectureInfo(content) {
  // Look for architecture-related content
  const architectureKeywords = [
    'architecture', 'component', 'service', 'database',
    'system design', 'pattern', 'model', 'microservice',
    'monolith', 'api', 'interface', 'frontend', 'backend'
  ];
  
  return extractContentByKeywords(content, architectureKeywords) || 
    `### Components
- Frontend: User interface components
- Backend: Server-side logic
- Database: Data storage solution

### Design Patterns
Recommended patterns for this implementation`;
}

/**
 * Extract best practices from the content
 * @param {string} content - The content to extract from
 * @returns {string} - Extracted best practices
 */
function extractBestPractices(content) {
  // Look for best practices content
  const bestPracticesKeywords = [
    'best practice', 'standard', 'convention', 'security',
    'performance', 'optimization', 'scalability', 'maintainability',
    'testing', 'quality', 'code style', 'guideline'
  ];
  
  return extractContentByKeywords(content, bestPracticesKeywords) ||
    `### Coding Standards
Follow consistent coding standards and conventions

### Security Considerations
Implement proper security measures

### Performance Optimization
Optimize for performance and scalability`;
}

/**
 * Extract implementation strategy from the content
 * @param {string} content - The content to extract from
 * @returns {string} - Extracted implementation strategy
 */
function extractImplementationStrategy(content) {
  // Look for implementation-related content
  const implementationKeywords = [
    'implementation', 'step', 'process', 'approach',
    'develop', 'build', 'create', 'setup', 'configure',
    'implement', 'deploy', 'workflow', 'lifecycle'
  ];
  
  return extractContentByKeywords(content, implementationKeywords) ||
    `1. **Setup Project Structure**
   - Initialize the project
   - Configure essential tools

2. **Develop Core Features**
   - Implement the main functionality
   - Create necessary components

3. **Testing and Deployment**
   - Test thoroughly
   - Deploy the application`;
}

/**
 * Extract cursor-optimized prompts from the content
 * @param {string} content - The content to extract from
 * @param {string} query - The original query
 * @returns {string} - Extracted prompts
 */
function extractCursorPrompts(content, query) {
  // Look for prompt-related content
  const promptKeywords = [
    'prompt', 'ask', 'query', 'question', 'request',
    'cursor', 'ai', 'assistant', 'command', 'instruction'
  ];
  
  // Extract or generate prompts
  const extractedPrompts = extractContentByKeywords(content, promptKeywords);
  if (extractedPrompts) return extractedPrompts;
  
  // If no prompts found, generate some based on the query
  const queryWords = query.split(' ').filter(word => word.length > 3);
  const topicWords = queryWords.length > 2 
    ? queryWords.slice(0, 3).join(' ') 
    : query;
  
  return `### Development Prompts
- "Create a detailed plan for implementing ${topicWords}"
- "Write code for the core functionality of ${topicWords}"
- "Generate tests for the ${topicWords} implementation"
- "Optimize the performance of the ${topicWords} solution"`;
}

/**
 * Extract content based on keywords
 * @param {string} content - The content to search in
 * @param {string[]} keywords - Keywords to look for
 * @returns {string|null} - Extracted content or null if none found
 */
function extractContentByKeywords(content, keywords) {
  const paragraphs = content.split('\n\n');
  const relevantParagraphs = [];
  
  // Find paragraphs containing keywords
  for (const paragraph of paragraphs) {
    const lowerParagraph = paragraph.toLowerCase();
    if (keywords.some(keyword => lowerParagraph.includes(keyword.toLowerCase()))) {
      relevantParagraphs.push(paragraph);
    }
  }
  
  return relevantParagraphs.length > 0 
    ? relevantParagraphs.join('\n\n') 
    : null;
} 