#!/bin/bash
set -e
rm -rf /home/andyphung/frappe-bench/apps/class_mgmt
mkdir -p /home/andyphung/frappe-bench/apps/class_mgmt/class_mgmt
rsync -av --exclude='__pycache__' /mnt/d/Xampp/htdocs/class-manager/class_mgmt/class_mgmt/ /home/andyphung/frappe-bench/apps/class_mgmt/class_mgmt/
cat <<EOF > /home/andyphung/frappe-bench/apps/class_mgmt/setup.py
from setuptools import setup, find_packages
setup(name="class_mgmt", version="0.0.1", packages=find_packages())
EOF
ls -R /home/andyphung/frappe-bench/apps/class_mgmt
