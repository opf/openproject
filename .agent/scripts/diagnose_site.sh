#!/bin/bash
set -e

echo "=== frappe.local site dir ==="
ls -la /home/andyphung/frappe-bench/sites/frappe.local/

echo ""
echo "=== site_config.json ==="
cat /home/andyphung/frappe-bench/sites/frappe.local/site_config.json

echo ""
echo "=== apps.txt ==="
cat /home/andyphung/frappe-bench/sites/frappe.local/apps.txt

echo ""
echo "=== Testing Frappe site resolution ==="
cd /home/andyphung/frappe-bench
./env/bin/python3 -c "
import frappe
# Test site resolution
import os
sites_path = 'sites'
for d in os.listdir(sites_path):
    full = os.path.join(sites_path, d)
    cfg = os.path.join(full, 'site_config.json')
    if os.path.isdir(full) and os.path.exists(cfg):
        print(f'Valid site: {d}')
    elif os.path.isdir(full):
        print(f'Dir without config: {d}')
"

echo ""
echo "=== currentsite.txt ==="
cat /home/andyphung/frappe-bench/sites/currentsite.txt

echo ""
echo "=== common_site_config default_site ==="
grep default_site /home/andyphung/frappe-bench/sites/common_site_config.json
