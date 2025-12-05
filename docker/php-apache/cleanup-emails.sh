#!/bin/bash
# Cleanup .eml files older than 24 hours

EML_DIR="/mail/eml"
HOURS=24

# Remove .eml files older than 24 hours
find "$EML_DIR" -name "*.eml" -type f -mtime +0 -delete 2>/dev/null

exit 0
