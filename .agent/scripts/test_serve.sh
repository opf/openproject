#!/bin/bash
# test_direct_serve.sh — Start bench from correct working dir with explicit site
set -e

cd /home/andyphung/frappe-bench

# Stop any existing serve processes
pkill -f "frappe serve" 2>/dev/null || true
sleep 2

# Clear all caches
./env/bin/bench --site frappe.local clear-cache 2>/dev/null || true

# Test bench console first to confirm frppe can see the site
echo "=== Testing bench console ==="
echo "quit" | ./env/bin/bench --site frappe.local console 2>&1 | head -5

echo ""
echo "=== Testing route resolution ==="
./env/bin/python3 -c "
import frappe
frappe.init(site='frappe.local', sites_path='sites')
frappe.connect()
from frappe.website.path_resolver import PathResolver
r = PathResolver('class_dashboard')
result = r.resolve()
print('Route:', result[0], type(result[1]).__name__)
frappe.destroy()
"

echo ""
echo "=== Starting server ==="
echo "Server will start in 3 seconds..."
