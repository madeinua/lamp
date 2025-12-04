#!/bin/bash
set -e

# SSL certificate directory
SSL_DIR="/etc/apache2/ssl"
CERT_FILE="$SSL_DIR/local-dev.crt"
KEY_FILE="$SSL_DIR/local-dev.key"

# Generate SSL certificate if it doesn't exist
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "=== Generating SSL certificate for local development ==="

    mkdir -p "$SSL_DIR"

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/C=DE/ST=Berlin/L=Berlin/O=LocalDevelopment/OU=IT/CN=*.local" \
        -addext "subjectAltName=DNS:localhost,DNS:*.local,DNS:*.test,DNS:*.dev" \
        2>/dev/null

    echo "✓ SSL certificate generated successfully"
    echo ""
fi

# Virtual hosts configuration
VHOSTS_DIR="/etc/apache2/sites-enabled"
VHOST_FILE="$VHOSTS_DIR/dev.conf"
VHOST_TEMPLATE="$VHOSTS_DIR/dev.conf.template"

# Create vhosts config from template if it doesn't exist
if [ ! -f "$VHOST_FILE" ] && [ -f "$VHOST_TEMPLATE" ]; then
    echo "=== Creating virtual hosts configuration from template ==="
    cp "$VHOST_TEMPLATE" "$VHOST_FILE"
    echo "✓ Virtual hosts configuration created"
    echo "  Edit docker/apache/vhosts/dev.conf to customize your domains"
    echo ""
fi

# Start cron in background
cron

# Start Apache in foreground
exec apache2-foreground
