#!/bin/bash
# Fix WordPress permissions for Docker environment
# Run this script when WordPress needs write access
# Usage: ./fix-permissions.sh [project-path]
# Example: ./fix-permissions.sh htdocs/myproject/wp-content

TARGET_PATH="${1:-htdocs}"

if [ ! -d "$TARGET_PATH" ]; then
    echo "Error: Directory '$TARGET_PATH' not found"
    echo "Usage: $0 [relative-path]"
    echo "Example: $0 htdocs/myproject/wp-content"
    exit 1
fi

# Convert to absolute path inside container
CONTAINER_PATH="/var/www/$TARGET_PATH"

echo "Setting file permissions for web server..."
echo "Target: $CONTAINER_PATH"

# Set ownership to www-data (user running Apache inside container)
docker exec dev-web chown -R www-data:www-data "$CONTAINER_PATH"

# Set proper permissions
docker exec dev-web find "$CONTAINER_PATH" -type d -exec chmod 755 {} \;
docker exec dev-web find "$CONTAINER_PATH" -type f -exec chmod 644 {} \;

echo "✓ Permissions fixed!"
echo ""
echo "Note: If you need to edit files from Windows/WSL, run: ./dev-permissions.sh $TARGET_PATH"
