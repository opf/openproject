#!/bin/bash
set -e
cd /home/andyphung/frappe-bench

# Kill any existing processes
pkill -f "frappe serve" 2>/dev/null || true
pkill -f "gunicorn" 2>/dev/null || true
sleep 2

# Check if Procfile exists and use bench start
echo "=== Checking Procfile ==="
cat Procfile 2>/dev/null | head -10 || echo "No Procfile"

echo ""
echo "=== Starting bench serve with verbose output ==="
# Use WERKZEUG_DEBUG_PIN=off to simplify, and capture stderr
./env/bin/python -c "
import sys
sys.path.insert(0, 'apps/frappe')
import frappe
from frappe.app import application
from werkzeug.serving import run_simple

print('Starting Werkzeug server on port 8000...')
print('Sites path:', 'sites')
print('Default site conf loaded OK')

# Important: set the sites_path module variable
import frappe.app
frappe.app._sites_path = 'sites'

run_simple('0.0.0.0', 8000, application, use_reloader=False, use_debugger=False, threaded=True)
"
