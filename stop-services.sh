#!/bin/bash
echo "Stopping AutoProgrammer services..."
pkill -f 'node.*server.js' || true
pkill -f 'node.*gateway.js' || true
pkill -f 'vite' || true
echo "Checking if any processes are still running on ports 4000, 5000, 5173, or 5174..."
for port in 4000 5000 5173 5174; do
    if lsof -ti:$port > /dev/null; then
        echo "Forcefully killing process on port $port..."
        lsof -ti:$port | xargs kill -9 || true
    fi
done
echo "All services stopped."
