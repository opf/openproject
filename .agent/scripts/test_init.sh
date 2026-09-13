#!/bin/bash
set -e
cd /home/andyphung/frappe-bench

./env/bin/python3 -c "
import frappe

# Simulate what app.py does
site = 'localhost'
frappe.init(site=site, sites_path='sites', force=True)

print('conf:', frappe.local.conf)
print('db_name:', frappe.local.conf.get('db_name', 'MISSING'))
print('site_path:', frappe.local.site_path)

import os
config_path = os.path.join('sites', site, 'site_config.json')
print('config exists:', os.path.exists(config_path))
if os.path.exists(config_path):
    with open(config_path) as f:
        print('raw config:', f.read())
"
