#!/bin/bash
# Restore file ownership for development/editing from host
# Run this script when you need to edit files from Windows/WSL
# Usage: ./dev-permissions.sh [project-path]
# Example: ./dev-permissions.sh htdocs/myproject/wp-content

TARGET_PATH="${1:-htdocs}"

if [ ! -d "$TARGET_PATH" ]; then
    echo "Error: Directory '$TARGET_PATH' not found"
    echo "Usage: $0 [relative-path]"
    echo "Example: $0 htdocs/myproject/wp-content"
    exit 1
fi

# Convert to absolute path inside container
CONTAINER_PATH="/var/www/$TARGET_PATH"

echo "Restoring file ownership for host user..."
echo "Target: $CONTAINER_PATH"

# Get host user ID
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Set ownership back to host user
docker exec dev-web chown -R $HOST_UID:$HOST_GID "$CONTAINER_PATH"

# Make directories and files readable by all (so www-data can still read)
docker exec dev-web find "$CONTAINER_PATH" -type d -exec chmod 775 {} \;
docker exec dev-web find "$CONTAINER_PATH" -type f -exec chmod 664 {} \;

echo "✓ Ownership restored to host user!"
echo ""
echo "Note: WordPress write operations (plugin updates, etc.) may fail."
echo "Run ./fix-permissions.sh $TARGET_PATH before updating plugins/themes in WordPress."
