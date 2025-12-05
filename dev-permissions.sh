#!/bin/bash
# Restore file ownership for development/editing from host
# Run this script when you need to edit files from Windows/WSL

echo "Restoring file ownership for host user..."

# Get host user ID
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Set ownership back to host user
docker exec dev-web chown -R $HOST_UID:$HOST_GID /var/www/htdocs/gesundheit/wp-content/

# Make directories and files readable by all (so www-data can still read)
docker exec dev-web find /var/www/htdocs/gesundheit/wp-content/ -type d -exec chmod 775 {} \;
docker exec dev-web find /var/www/htdocs/gesundheit/wp-content/ -type f -exec chmod 664 {} \;

echo "✓ Ownership restored to host user!"
echo ""
echo "Note: WordPress write operations (plugin updates, etc.) may fail."
echo "Run ./fix-permissions.sh before updating plugins/themes in WordPress."
