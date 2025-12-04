#!/bin/bash

# Generate Windows hosts file entries for all virtual hosts

echo "# Docker LAMP Stack - Local Development Domains"
echo "# Add these entries to your Windows hosts file:"
echo "# Location: C:\\Windows\\System32\\drivers\\etc\\hosts"
echo "# (Open Notepad as Administrator to edit)"
echo ""

# Extract all ServerName entries except localhost
grep "ServerName" docker/apache/vhosts/dev.conf | \
    awk '{print $2}' | \
    sort -u | \
    grep -v "^localhost$" | \
    while read -r domain; do
        echo "127.0.0.1    $domain"
    done

echo ""
echo "# After adding these entries, you can access your sites at:"
grep "ServerName" docker/apache/vhosts/dev.conf | \
    awk '{print $2}' | \
    sort -u | \
    grep -v "^localhost$" | \
    while read -r domain; do
        echo "#   http://$domain"
        echo "#   https://$domain"
    done
