# Contributing to AutoProgrammer

Thank you for your interest in contributing to AutoProgrammer! This document provides guidelines and instructions for contributing to this project.

## Development Setup

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/AutoProgrammer.git
   cd AutoProgrammer
   ```
3. Set up the development environment:
   ```bash
   # Install dependencies
   npm install
   
   # Install development dependencies
   npm install --save-dev nodemon jest
   
   # Create .env file from template
   cp .env.template .env
   ```

## Project Structure

The project follows a microservices architecture:

```
AutoProgrammer/
├── services/               # Microservices
│   └── output-service.js   # Output file monitoring service
├── index.js                # Main application entry point
├── index.html              # UI for the Electron app
├── .env.template           # Environment variable template
├── setup.sh                # Setup script
├── last-resort.command     # Simple integration script
├── super-simple.sh         # Minimal integration script
├── docker-compose.yml      # Docker configuration
└── Dockerfile              # Docker image definition
```

## Development Workflow

1. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and ensure they follow the project's coding style

3. Test your changes:
   ```bash
   # Run in development mode
   npm run dev
   
   # Test the minimal integration script
   ./super-simple.sh
   ```

4. Commit your changes with a descriptive message:
   ```bash
   git commit -m "Add feature: description of your changes"
   ```

5. Push your branch to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```

6. Open a Pull Request from your fork to the main repository

## Coding Standards

- Use ES6+ features where appropriate
- Follow the existing code style (indent with 2 spaces)
- Comment your code, especially complex functions
- Keep functions small and focused on a single task
- Use async/await for asynchronous operations
- Add appropriate error handling

## Testing

Before submitting your changes, please test:

1. The main application with `npm start`
2. The integration scripts independently
3. If possible, test on multiple platforms (macOS, Windows, Linux)

## Pull Request Process

1. Update the README.md or documentation with details of your changes
2. Update the CHANGELOG.md with a description of your changes
3. If possible, include screenshots or examples of the new features
4. The PR will be reviewed and merged when approved

## Adding New Features

When adding new features, consider:

1. Will this work across different platforms?
2. Does this maintain backward compatibility?
3. Can this be implemented with zero dependencies (for the minimal scripts)?
4. Is this feature aligned with the project's goals?

## Communication

For questions or discussions:

- Open an issue on GitHub
- Join our community discussions (link TBD)

Thank you for contributing to AutoProgrammer! 