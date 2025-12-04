#!/bin/bash

# Start Docker LAMP Stack
# This script builds and starts all containers

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Starting Docker LAMP Stack...${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker Desktop first.${NC}"
    exit 1
fi

# Build and start containers
echo "Building and starting containers..."
docker-compose up -d --build

echo ""
echo -e "${GREEN}✓ Docker LAMP Stack is running!${NC}"
echo ""
echo "Services:"
echo "  - Web Server: http://localhost (HTTP) and https://localhost (HTTPS)"
echo "  - MySQL: localhost:3306"
echo "    - Root: root/root | App: app/app (database: app)"
echo "    - Using custom config from docker/mysql/my.cnf"
echo "  - Mailpit Web UI: http://localhost:8025"
echo "  - SMTP Server: localhost:1025"
echo ""
echo "Virtual Hosts:"
grep "ServerName" docker/apache/vhosts/dev.conf | awk '{print "  - "$2}' | sort -u | while read -r line; do
    domain=$(echo "$line" | awk '{print $2}')
    if [ "$domain" != "localhost" ]; then
        echo "$line (remember to add to hosts file)"
    else
        echo "$line"
    fi
done
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: ./stop.sh or docker-compose down"
echo ""
echo -e "${YELLOW}Don't forget to update your Windows hosts file!${NC}"
echo "Run: notepad C:\\Windows\\System32\\drivers\\etc\\hosts (as Administrator)"
echo "Or use: ./update-hosts.sh to generate entries"
