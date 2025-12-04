#!/bin/bash

# Docker LAMP Stack Test Suite
# Tests all components: PHP, MySQL, SSL, Email, Virtual Hosts, etc.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test result function
test_result() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} - $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [ -n "$3" ]; then
            echo -e "  ${RED}Error: $3${NC}"
        fi
    fi
}

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Docker LAMP Stack - Test Suite       ║${NC}"
echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo ""

# ============================================
# 1. DOCKER CONTAINERS
# ============================================
echo -e "${BLUE}[1] Testing Docker Containers...${NC}"

# Check if Docker is running
if docker info > /dev/null 2>&1; then
    test_result 0 "Docker daemon is running"
else
    test_result 1 "Docker daemon is running" "Docker is not running. Start Docker Desktop."
    exit 1
fi

# Check dev-web container
if docker ps | grep -q "dev-web"; then
    test_result 0 "dev-web container is running"
else
    test_result 1 "dev-web container is running" "Run ./start.sh to start containers"
fi

# Check dev-db container
if docker ps | grep -q "dev-db"; then
    test_result 0 "dev-db container is running"
else
    test_result 1 "dev-db container is running"
fi

# Check dev-mailpit container
if docker ps | grep -q "dev-mailpit"; then
    test_result 0 "dev-mailpit container is running"
else
    test_result 1 "dev-mailpit container is running"
fi

echo ""

# ============================================
# 2. WEB SERVER & PHP
# ============================================
echo -e "${BLUE}[2] Testing Web Server & PHP...${NC}"

# Test HTTP response
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    test_result 0 "HTTP server responds (port 80)"
else
    test_result 1 "HTTP server responds (port 80)" "Got HTTP $HTTP_CODE"
fi

# Test HTTPS response
HTTPS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost/ 2>/dev/null || echo "000")
if [ "$HTTPS_CODE" = "200" ]; then
    test_result 0 "HTTPS server responds (port 443)"
else
    test_result 1 "HTTPS server responds (port 443)" "Got HTTP $HTTPS_CODE"
fi

# Test PHP execution
PHP_VERSION=$(curl -s http://localhost/ 2>/dev/null | grep -o "PHP [0-9]\.[0-9]\.[0-9]*" | head -1)
if [ -n "$PHP_VERSION" ]; then
    test_result 0 "PHP is executing ($PHP_VERSION)"
else
    test_result 1 "PHP is executing"
fi

# Check PHP extensions
PHP_EXTENSIONS=$(docker exec dev-web php -m 2>/dev/null)
for ext in mysqli pdo_mysql gd zip intl curl mbstring; do
    if echo "$PHP_EXTENSIONS" | grep -q "^$ext$"; then
        test_result 0 "PHP extension '$ext' is loaded"
    else
        test_result 1 "PHP extension '$ext' is loaded"
    fi
done

# Check Apache modules
APACHE_MODULES=$(docker exec dev-web apache2ctl -M 2>/dev/null)
for mod in rewrite ssl headers; do
    if echo "$APACHE_MODULES" | grep -q "${mod}_module"; then
        test_result 0 "Apache module '$mod' is enabled"
    else
        test_result 1 "Apache module '$mod' is enabled"
    fi
done

echo ""

# ============================================
# 3. MYSQL DATABASE
# ============================================
echo -e "${BLUE}[3] Testing MySQL Database...${NC}"

# Wait for MySQL to be ready
sleep 2

# Test MySQL is responding
if docker exec dev-db mysqladmin -u root -proot ping > /dev/null 2>&1; then
    test_result 0 "MySQL server is responding"
else
    test_result 1 "MySQL server is responding" "MySQL may still be starting up"
fi

# Test root login
if docker exec dev-db mysql -u root -proot -e "SELECT 1;" > /dev/null 2>&1; then
    test_result 0 "MySQL root login works"
else
    test_result 1 "MySQL root login works"
fi

# Test app database exists
if docker exec dev-db mysql -u root -proot -e "USE app;" > /dev/null 2>&1; then
    test_result 0 "Database 'app' exists"
else
    test_result 1 "Database 'app' exists"
fi

# Test app user can connect
if docker exec dev-db mysql -u app -papp -e "SELECT 1;" > /dev/null 2>&1; then
    test_result 0 "MySQL user 'app' can login"
else
    test_result 1 "MySQL user 'app' can login"
fi

# Test PHP can connect to MySQL
PHP_MYSQL_TEST=$(docker exec dev-web php -r "try { new PDO('mysql:host=db;dbname=app', 'app', 'app'); echo 'OK'; } catch(Exception \$e) { echo 'FAIL'; }" 2>/dev/null)
if [ "$PHP_MYSQL_TEST" = "OK" ]; then
    test_result 0 "PHP can connect to MySQL (PDO)"
else
    test_result 1 "PHP can connect to MySQL (PDO)"
fi

# Check character set
CHARSET=$(docker exec dev-db mysql -u root -proot -e "SHOW VARIABLES LIKE 'character_set_server';" 2>/dev/null | grep character_set_server | awk '{print $2}')
if [ "$CHARSET" = "utf8mb4" ]; then
    test_result 0 "MySQL character set is utf8mb4"
else
    test_result 1 "MySQL character set is utf8mb4" "Got: $CHARSET"
fi

echo ""

# ============================================
# 4. SSL CERTIFICATES
# ============================================
echo -e "${BLUE}[4] Testing SSL Certificates...${NC}"

# Check SSL certificate exists (generic certificate for all domains)
if [ -f "docker/apache/ssl/local-dev.crt" ] && [ -f "docker/apache/ssl/local-dev.key" ]; then
    test_result 0 "Generic SSL certificate exists (local-dev.crt/key)"
else
    test_result 1 "Generic SSL certificate exists (local-dev.crt/key)"
fi

# Test SSL certificate validity
if openssl x509 -in docker/apache/ssl/local-dev.crt -noout -checkend 0 > /dev/null 2>&1; then
    test_result 0 "SSL certificate is valid (not expired)"
else
    test_result 1 "SSL certificate is valid (not expired)"
fi

# Test SSL certificate details
CERT_SUBJECT=$(openssl x509 -in docker/apache/ssl/local-dev.crt -noout -subject 2>/dev/null | grep -o "CN=.*")
if [ -n "$CERT_SUBJECT" ]; then
    test_result 0 "SSL certificate has valid subject"
else
    test_result 1 "SSL certificate has valid subject"
fi

echo ""

# ============================================
# 5. MAILPIT EMAIL CATCHER
# ============================================
echo -e "${BLUE}[5] Testing Mailpit Email System...${NC}"

# Test Mailpit web UI
MAILPIT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8025/ 2>/dev/null || echo "000")
if [ "$MAILPIT_CODE" = "200" ]; then
    test_result 0 "Mailpit web UI is accessible (port 8025)"
else
    test_result 1 "Mailpit web UI is accessible (port 8025)" "Got HTTP $MAILPIT_CODE"
fi

# Test SMTP port is listening
if nc -z localhost 1025 2>/dev/null; then
    test_result 0 "Mailpit SMTP server is listening (port 1025)"
else
    # Try with docker exec as fallback
    if docker exec dev-mailpit nc -z localhost 1025 2>/dev/null; then
        test_result 0 "Mailpit SMTP server is listening (port 1025)"
    else
        test_result 1 "Mailpit SMTP server is listening (port 1025)"
    fi
fi

# Test sending email via PHP
TEST_EMAIL_RESULT=$(docker exec dev-web php -r "if(mail('test@example.com', 'Test', 'Test message')) { echo 'OK'; } else { echo 'FAIL'; }" 2>/dev/null)
if [ "$TEST_EMAIL_RESULT" = "OK" ]; then
    test_result 0 "PHP mail() function works"

    # Wait a moment for email to be processed
    sleep 2

    # Check if email was received by Mailpit
    MAILPIT_MESSAGES=$(curl -s http://localhost:8025/api/v1/messages 2>/dev/null | grep -o '"total":[0-9]*' | cut -d: -f2)
    if [ -n "$MAILPIT_MESSAGES" ] && [ "$MAILPIT_MESSAGES" -gt 0 ]; then
        test_result 0 "Email captured by Mailpit ($MAILPIT_MESSAGES messages)"
    else
        test_result 1 "Email captured by Mailpit" "No messages found"
    fi
else
    test_result 1 "PHP mail() function works"
fi

# Check mail directory exists
if [ -d "mail" ]; then
    test_result 0 "Mail directory exists"
else
    test_result 1 "Mail directory exists"
fi

echo ""

# ============================================
# 6. VIRTUAL HOSTS
# ============================================
echo -e "${BLUE}[6] Testing Virtual Hosts Configuration...${NC}"

# Check vhosts config file
if [ -f "docker/apache/vhosts/dev.conf" ]; then
    test_result 0 "Virtual hosts config file exists"

    # Count virtual hosts
    VHOST_COUNT=$(grep -c "ServerName" docker/apache/vhosts/dev.conf || echo "0")
    if [ "$VHOST_COUNT" -gt 0 ]; then
        test_result 0 "Virtual hosts configured ($VHOST_COUNT domains)"
    else
        test_result 1 "Virtual hosts configured"
    fi
else
    test_result 1 "Virtual hosts config file exists"
fi

# Test if vhosts are loaded in Apache
APACHE_VHOSTS=$(docker exec dev-web apachectl -S 2>/dev/null | grep "port 80" | wc -l)
if [ "$APACHE_VHOSTS" -gt 1 ]; then
    test_result 0 "Apache loaded multiple virtual hosts"
else
    test_result 1 "Apache loaded multiple virtual hosts"
fi

echo ""

# ============================================
# 7. FILE STRUCTURE
# ============================================
echo -e "${BLUE}[7] Testing File Structure...${NC}"

# Check important directories
REQUIRED_DIRS=(
    "htdocs"
    "docker/php"
    "docker/apache/vhosts"
    "docker/apache/ssl"
    "docker/mysql"
    "mail"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        test_result 0 "Directory '$dir' exists"
    else
        test_result 1 "Directory '$dir' exists"
    fi
done

# Check important files
REQUIRED_FILES=(
    "docker-compose.yml"
    "docker/php/php.ini"
    "docker/mysql/my.cnf"
    "docker/php-apache/Dockerfile"
    "start.sh"
    "stop.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        test_result 0 "File '$file' exists"
    else
        test_result 1 "File '$file' exists"
    fi
done

echo ""

# ============================================
# 8. CONFIGURATION
# ============================================
echo -e "${BLUE}[8] Testing Configuration...${NC}"

# Check PHP configuration
PHP_MEMORY=$(docker exec dev-web php -r "echo ini_get('memory_limit');" 2>/dev/null)
if [ "$PHP_MEMORY" = "512M" ]; then
    test_result 0 "PHP memory_limit is 512M (from config)"
else
    test_result 1 "PHP memory_limit is 512M (from config)" "Got: $PHP_MEMORY"
fi

PHP_MAX_EXEC=$(docker exec dev-web php -r "echo ini_get('max_execution_time');" 2>/dev/null)
if [ "$PHP_MAX_EXEC" = "3600" ]; then
    test_result 0 "PHP max_execution_time is 3600s (from config)"
else
    test_result 1 "PHP max_execution_time is 3600s (from config)" "Got: $PHP_MAX_EXEC"
fi

# Check MySQL configuration
INNODB_BUFFER=$(docker exec dev-db mysql -u root -proot -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" 2>/dev/null | grep innodb | awk '{print $2}')
if [ "$INNODB_BUFFER" = "268435456" ]; then  # 256M in bytes
    test_result 0 "MySQL InnoDB buffer pool is 256M (from config)"
else
    test_result 1 "MySQL InnoDB buffer pool is 256M (from config)" "Got: $INNODB_BUFFER bytes"
fi

echo ""

# ============================================
# SUMMARY
# ============================================
echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║           TEST RESULTS SUMMARY         ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total Tests:  ${BLUE}${TESTS_TOTAL}${NC}"
echo -e "Passed:       ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed:       ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ ALL TESTS PASSED!                 ║${NC}"
    echo -e "${GREEN}║   Your Docker LAMP Stack is perfect!  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ✗ SOME TESTS FAILED                  ║${NC}"
    echo -e "${RED}║   Please review the errors above       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Common fixes:"
    echo "  - Run: ./start.sh to start all containers"
    echo "  - Run: docker-compose restart to restart services"
    echo "  - Check logs: docker-compose logs -f"
    exit 1
fi
