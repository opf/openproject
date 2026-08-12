#!/bin/bash
set -e

SITES="/home/andyphung/frappe-bench/sites"

# Option 1: Make localhost a symlink to frappe.local
# This way Host: localhost resolves to the frappe.local site

echo "=== Removing broken localhost site ==="
rm -rf "$SITES/localhost"

echo "=== Creating symlink: localhost -> frappe.local ==="
ln -s "$SITES/frappe.local" "$SITES/localhost"

echo "=== Verifying ==="
ls -la "$SITES/localhost"
echo "---"
cat "$SITES/localhost/apps.txt"
echo "---"
echo "Done!"
