#!/bin/bash
set -e
cd /home/andyphung/frappe-bench/apps/class_mgmt/class_mgmt

# Create the module subdirectory (class_mgmt/class_mgmt/class_mgmt/)
# This mirrors how LMS does it: lms/lms/lms/doctype/
mkdir -p class_mgmt

# Create __init__.py for the module package
touch class_mgmt/__init__.py

# Move (or symlink) doctype/ into the module dir
if [ -d "doctype" ] && [ ! -d "class_mgmt/doctype" ]; then
    echo "Moving doctype/ into class_mgmt/class_mgmt/"
    cp -r doctype class_mgmt/
fi

echo "=== Structure after fix ==="
echo "apps/class_mgmt/"
ls -F ../
echo ""
echo "apps/class_mgmt/class_mgmt/"
ls -F .
echo ""
echo "apps/class_mgmt/class_mgmt/class_mgmt/"
ls -F class_mgmt/
echo ""
echo "apps/class_mgmt/class_mgmt/class_mgmt/doctype/"
ls class_mgmt/doctype/

echo ""
echo "=== Verifying import path ==="
cd /home/andyphung/frappe-bench
./env/bin/python3 -c "
import class_mgmt.class_mgmt.doctype.ec_class.ec_class as m
print('Import OK:', m.__file__)
"
