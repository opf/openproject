#!/bin/bash
set -e

SITES="/home/andyphung/frappe-bench/sites"

# Set currentsite.txt
echo "frappe.local" > "$SITES/currentsite.txt"
echo "currentsite.txt: $(cat $SITES/currentsite.txt)"

# Ensure frappe.local apps.txt has all required apps
cat > "$SITES/frappe.local/apps.txt" << 'EOF'
frappe
erpnext
lms
class_mgmt
ielts_assessment
EOF
echo "frappe.local apps.txt:"
cat "$SITES/frappe.local/apps.txt"

echo "---"
echo "Done!"
