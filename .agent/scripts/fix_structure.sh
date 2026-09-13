#!/bin/bash
# fix_structure.sh — Build the correct Frappe app structure from Windows source
set -e

APP_ROOT="/home/andyphung/frappe-bench/apps/class_mgmt"
WIN_APP="/mnt/d/Xampp/htdocs/class-manager/class_mgmt"

echo "=== Step 1: Purge existing WSL app ==="
rm -rf "$APP_ROOT"
mkdir -p "$APP_ROOT/class_mgmt"

echo "=== Step 2: Sync app root files (setup.py, requirements.txt) ==="
rsync -av --include="*.py" --include="*.txt" --exclude="class_mgmt/" \
    "$WIN_APP/" "$APP_ROOT/"

echo "=== Step 3: Sync Python module files (hooks.py, api.py, engines, www, public) ==="
# Sync everything from class_mgmt/class_mgmt/ INTO app_root/class_mgmt/
rsync -av --exclude='__pycache__' --exclude='class_mgmt/' \
    "$WIN_APP/class_mgmt/" "$APP_ROOT/class_mgmt/"

echo "=== Step 4: Sync doctype folder (from triple-nested to correct location) ==="
# The doctype/ files are in class_mgmt/class_mgmt/class_mgmt/doctype/
mkdir -p "$APP_ROOT/class_mgmt/class_mgmt"
rsync -av --exclude='__pycache__' \
    "$WIN_APP/class_mgmt/class_mgmt/" "$APP_ROOT/class_mgmt/class_mgmt/"

echo "=== Step 5: Set correct __init__.py files ==="
# App root level __init__.py
touch "$APP_ROOT/__init__.py"

# Module level __init__.py
if [ ! -f "$APP_ROOT/class_mgmt/__init__.py" ]; then
    echo '# class_mgmt module' > "$APP_ROOT/class_mgmt/__init__.py"
fi

echo "=== Step 6: Verify structure ==="
find "$APP_ROOT" -name "hooks.py" -o -name "api.py" | head -20
echo ""
find "$APP_ROOT/class_mgmt" -name "*.json" | head -10
echo ""
echo "=== Done! ==="
