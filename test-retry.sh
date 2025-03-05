#!/bin/bash

# Test script for AutoProgrammer retry functionality
# This script simulates a timeout by making a complex query

echo "Testing AutoProgrammer automatic retry functionality..."
echo "This will make a complex query that is likely to trigger a timeout"
echo "and test if the automatic retry mechanism works correctly."
echo ""

# Get the base URL from the user or use default
read -p "Enter API Gateway URL [http://localhost:4000]: " API_URL
API_URL=${API_URL:-http://localhost:4000}

# Create a complex query that will likely timeout
COMPLEX_QUERY="Please write a complete implementation of a distributed blockchain system with smart contracts, including all the cryptographic functions, consensus algorithms, and networking code. The implementation should be in Rust and should include detailed comments explaining every part of the code. Also include unit tests and integration tests."

echo ""
echo "Sending complex query to trigger timeout and test retry mechanism..."
echo "Query: ${COMPLEX_QUERY:0:100}..."
echo ""

# Make the request
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$COMPLEX_QUERY\"}" \
  "$API_URL/ask" | jq .

echo ""
echo "Check the logs to see if retry attempts were made."
echo "You should see messages about retrying in the API Gateway and UI logs." 