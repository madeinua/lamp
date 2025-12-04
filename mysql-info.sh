#!/bin/bash

# Display MySQL Configuration Info
# This script shows current MySQL settings and how to connect

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}MySQL Configuration Info${NC}"
echo "========================================"
echo ""

echo -e "${BLUE}Connection Details:${NC}"
echo "  Host (from Windows):  localhost or 127.0.0.1"
echo "  Host (from PHP):      db"
echo "  Port:                 3306"
echo ""
echo "  Root User:            root"
echo "  Root Password:        root"
echo ""
echo "  App Database:         app"
echo "  App User:             app"
echo "  App Password:         app"
echo ""

echo -e "${BLUE}Configuration File:${NC}"
echo "  Location: docker/mysql/my.cnf"
echo ""

echo -e "${BLUE}Key Settings:${NC}"
echo "  Character Set:        utf8mb4"
echo "  Collation:            utf8mb4_general_ci"
echo "  InnoDB Buffer Pool:   256M"
echo "  Max Packet Size:      32M"
echo "  Max Connections:      150"
echo ""

echo -e "${BLUE}Connect from Command Line:${NC}"
echo "  From Windows:"
echo "    mysql -h localhost -u root -proot"
echo "    mysql -h localhost -u app -papp app"
echo ""
echo "  From WSL/Linux:"
echo "    mysql -h 127.0.0.1 -u root -proot"
echo ""
echo "  From Docker container:"
echo "    docker exec -it dev-db mysql -u root -proot"
echo ""

echo -e "${BLUE}Connect from PHP:${NC}"
echo '  $pdo = new PDO("mysql:host=db;dbname=app;charset=utf8mb4", "app", "app");'
echo ""

echo -e "${BLUE}View Current MySQL Variables:${NC}"
echo "  docker exec -it dev-db mysql -u root -proot -e 'SHOW VARIABLES;'"
echo ""

echo -e "${BLUE}Import SQL File:${NC}"
echo "  docker exec -i dev-db mysql -u root -proot app < yourfile.sql"
echo ""

echo -e "${BLUE}Export Database:${NC}"
echo "  docker exec dev-db mysqldump -u root -proot app > backup.sql"
echo ""

if docker ps | grep -q "dev-db"; then
    echo -e "${GREEN}✓ MySQL container is running${NC}"
    echo ""
    echo "Testing connection..."
    if docker exec dev-db mysqladmin -u root -proot ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓ MySQL is responding${NC}"
        echo ""
        echo "Current databases:"
        docker exec dev-db mysql -u root -proot -e "SHOW DATABASES;" 2>/dev/null
    else
        echo "⚠ MySQL is not responding yet (may still be starting)"
    fi
else
    echo "⚠ MySQL container is not running"
    echo "Start it with: ./start.sh"
fi
