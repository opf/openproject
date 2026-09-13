#!/bin/bash
set -e
cd /home/andyphung/frappe-bench

./env/bin/python3 -c "
import frappe, os
frappe.init(site='frappe.local', sites_path='sites')
frappe.connect()

# Where does frappe think the app is?
app_path = frappe.get_app_path('class_mgmt')
print(f'App path: {app_path}')
print(f'App path exists: {os.path.exists(app_path)}')

# Check www location
www_in_app = os.path.join(app_path, 'www', 'class_dashboard.html')
www_parent = os.path.join(os.path.dirname(app_path), 'www', 'class_dashboard.html')
print(f'www in app_path: {www_in_app} exists={os.path.exists(www_in_app)}')
print(f'www in parent:   {www_parent} exists={os.path.exists(www_parent)}')

# List what's actually in the app path
print(f'Contents of app_path: {os.listdir(app_path)}')

# Check the installed app metadata
import importlib
mod = importlib.import_module('class_mgmt')
print(f'Module __file__: {mod.__file__}')
print(f'Module __path__: {mod.__path__}')

frappe.destroy()
"
