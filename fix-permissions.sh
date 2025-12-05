#!/bin/bash
# Fix WordPress permissions for Docker environment
# Run this script when WordPress needs write access

echo "Setting WordPress file permissions for web server..."

# Set ownership to www-data (user running Apache inside container)
docker exec dev-web chown -R www-data:www-data /var/www/htdocs/gesundheit/wp-content/

# Set proper permissions
docker exec dev-web find /var/www/htdocs/gesundheit/wp-content/ -type d -exec chmod 755 {} \;
docker exec dev-web find /var/www/htdocs/gesundheit/wp-content/ -type f -exec chmod 644 {} \;

echo "✓ Permissions fixed!"
echo ""
echo "Note: If you need to edit files from Windows/WSL, run: ./dev-permissions.sh"
