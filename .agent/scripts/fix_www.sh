#!/bin/bash
# fix_www.sh — Move www and public to app root level (Frappe expects them there)
set -e

APP_ROOT="/home/andyphung/frappe-bench/apps/class_mgmt"
MODULE_DIR="$APP_ROOT/class_mgmt"

echo "=== Moving www/ to app root level ==="
# Copy www from module level to app root
cp -r "$MODULE_DIR/www" "$APP_ROOT/www"

echo "=== Moving public/ to app root level ==="
# Copy public from module level to app root  
if [ -d "$MODULE_DIR/public" ]; then
    cp -r "$MODULE_DIR/public" "$APP_ROOT/public"
fi

echo "=== Verifying structure ==="
echo "App root:"
ls -F "$APP_ROOT/"
echo ""
echo "www contents:"
ls -F "$APP_ROOT/www/"

echo ""
echo "=== Done! ==="
