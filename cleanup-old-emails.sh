#!/bin/bash
# Manual script to cleanup old .eml files
# Run this from the project root: ./cleanup-old-emails.sh

# Remove .eml files older than 1 day (24 hours)
find mail/eml -name "*.eml" -type f -mtime +0 -delete 2>/dev/null

# Count remaining files
REMAINING=$(find mail/eml -name "*.eml" -type f | wc -l)

echo "✓ Cleaned up .eml files older than 24 hours"
echo "  Remaining files: $REMAINING"
