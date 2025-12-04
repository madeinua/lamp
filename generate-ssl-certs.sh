#!/bin/bash

# SSL Certificate Generation Script for Local Development
# This script generates a single self-signed SSL certificate for all local domains

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# SSL directory
SSL_DIR="./docker/apache/ssl"

# Certificate files
CERT_FILE="$SSL_DIR/local-dev.crt"
KEY_FILE="$SSL_DIR/local-dev.key"

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

echo -e "${YELLOW}Generating generic SSL certificate for local development...${NC}"
echo ""

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}✓${NC} Certificate already exists, skipping..."
    echo ""
    echo "Certificate: $CERT_FILE"
    echo "Key: $KEY_FILE"
    exit 0
fi

# Generate a single self-signed certificate valid for 365 days
# This certificate will work for all local domains
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/C=DE/ST=Berlin/L=Berlin/O=LocalDevelopment/OU=IT/CN=*.local" \
    -addext "subjectAltName=DNS:localhost,DNS:*.local,DNS:*.test,DNS:*.dev" \
    2>/dev/null

echo -e "${GREEN}✓${NC} Generic SSL certificate created successfully!"
echo ""
echo "Certificate: $CERT_FILE"
echo "Key: $KEY_FILE"
echo ""
echo "This certificate will work for all your local domains."
echo ""
echo "To trust this certificate in your browser:"
echo "1. Import $CERT_FILE into your system's certificate store"
echo "2. Mark it as trusted for SSL/TLS"
echo ""
echo "Note: This is a self-signed certificate for development only."
