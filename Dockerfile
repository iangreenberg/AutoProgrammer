FROM node:18-slim

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Make scripts executable
RUN chmod +x *.sh *.command

# Create environment file from template
RUN cp .env.template .env

# Expose port if needed
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PATH="/app/node_modules/.bin:${PATH}"

# Command to run the application
CMD ["npm", "start"] 