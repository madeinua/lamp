#!/bin/bash
# Email wrapper script - saves .eml files AND sends to Mailpit
# Based on XAMPP sendmail behavior

# Directory for .eml files (inside container)
EML_DIR="/mail/eml"

# Create directory if it doesn't exist
mkdir -p "$EML_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
EML_FILE="$EML_DIR/${TIMESTAMP}.eml"

# Read email from STDIN
EMAIL_CONTENT=$(cat)

# Check if file already exists, add suffix if needed
COUNTER=1
FINAL_FILE="$EML_FILE"
while [ -f "$FINAL_FILE" ]; do
    FINAL_FILE="${EML_FILE%.eml}_${COUNTER}.eml"
    COUNTER=$((COUNTER + 1))
done

# Save to .eml file
echo "$EMAIL_CONTENT" > "$FINAL_FILE"

# Also send to Mailpit via msmtp
echo "$EMAIL_CONTENT" | /usr/bin/msmtp -t

exit 0
