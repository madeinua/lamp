#!/bin/bash

# Stop Docker LAMP Stack

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stopping Docker LAMP Stack...${NC}"
echo ""

docker-compose down

echo ""
echo -e "${GREEN}✓ Docker LAMP Stack stopped successfully!${NC}"
echo ""
echo "To start again: ./start.sh or docker-compose up -d"
