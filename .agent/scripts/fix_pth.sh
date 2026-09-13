#!/bin/bash
set -e
cd /home/andyphung/frappe-bench

SITE_PKGS="./env/lib/python3.12/site-packages"

echo "=== Step 1: Remove modern editable install ==="
./env/bin/pip uninstall class_mgmt -y 2>&1 | tail -3

echo ""
echo "=== Step 2: Create simple .pth file (same as LMS) ==="
echo "/home/andyphung/frappe-bench/apps/class_mgmt" > "$SITE_PKGS/class_mgmt.pth"
cat "$SITE_PKGS/class_mgmt.pth"

echo ""
echo "=== Step 3: Verify import ==="
./env/bin/python3 -c "
import class_mgmt
print('__file__:', class_mgmt.__file__)
print('__path__:', class_mgmt.__path__)
print('__version__:', getattr(class_mgmt, '__version__', 'N/A'))
"

echo ""
echo "=== Step 4: Verify frappe.get_app_path ==="
./env/bin/python3 -c "
import frappe, os
frappe.init(site='frappe.local', sites_path='sites')
frappe.connect()
p = frappe.get_app_path('class_mgmt')
print('App path:', p)
www = os.path.join(p, 'www', 'class_dashboard.html')
print('www exists:', os.path.exists(www))
frappe.destroy()
"
