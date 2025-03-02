#!/bin/bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping AutoProgrammer services...${NC}"

# Stop processes by port number
for port in 5000 4000 5173 5174; do
  if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}Stopping process on port $port...${NC}"
    lsof -ti ":$port" | xargs kill -9 2>/dev/null || true
  fi
done

echo -e "${GREEN}All services stopped.${NC}"
