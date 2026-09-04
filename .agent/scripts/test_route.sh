#!/bin/bash
# test_route.sh — Test if Frappe can resolve the class_dashboard route
cd /home/andyphung/frappe-bench

./env/bin/python3 -c "
import frappe
frappe.init(site='localhost', sites_path='sites')
frappe.connect()

# Check if www page resolution works
from frappe.website.path_resolver import PathResolver
try:
    resolver = PathResolver('class_dashboard')
    req = resolver.resolve()
    print('Route resolved:', req)
except Exception as e:
    print('Route error:', e)

# Check raw app www files
import importlib.util, os
app_www = '/home/andyphung/frappe-bench/apps/class_mgmt/class_mgmt/www'
print('www files:', os.listdir(app_www))
frappe.destroy()
"
