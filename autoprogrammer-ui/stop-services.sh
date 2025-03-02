#!/bin/bash
echo "Stopping AutoProgrammer services..."
pkill -f 'node.*server\|gateway\|vite'
echo "All services stopped."
