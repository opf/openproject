#!/bin/bash
set -e
cd /home/andyphung/frappe-bench

echo "=== Reinstalling class_mgmt in editable mode ==="
./env/bin/pip install -e apps/class_mgmt 2>&1 | tail -5

echo ""
echo "=== Testing import ==="
./env/bin/python3 -c "
import class_mgmt
print('__file__:', class_mgmt.__file__)
print('__path__:', class_mgmt.__path__)
print('__version__:', getattr(class_mgmt, '__version__', 'N/A'))
"

echo ""
echo "=== Testing frappe.get_app_path ==="
./env/bin/python3 -c "
import frappe, os
frappe.init(site='frappe.local', sites_path='sites')
frappe.connect()
p = frappe.get_app_path('class_mgmt')
print('App path:', p)
print('www exists:', os.path.exists(os.path.join(p, 'www', 'class_dashboard.html')))
frappe.destroy()
"
