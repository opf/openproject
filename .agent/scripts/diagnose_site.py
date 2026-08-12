import frappe
import json

def diagnose():
    try:
        frappe.connect()
        print("=== Frappe Site Diagnosis ===")
        
        # 1. Check Site Config
        print(f"Site: {frappe.local.site}")
        print(f"User: {frappe.session.user}")
        
        # 2. Check Installed Apps
        installed_apps = frappe.get_installed_apps()
        print(f"Installed Apps: {', '.join(installed_apps)}")
        if "class_mgmt" not in installed_apps:
            print("WARNING: 'class_mgmt' is NOT installed on this site.")
        
        # 3. Check DocTypes
        doc_to_check = ["EC Class", "EC Class Session", "EC Attendance"]
        for dt in doc_to_check:
            try:
                count = frappe.db.count(dt)
                print(f"DocType '{dt}': FOUND ({count} records)")
            except Exception as e:
                print(f"DocType '{dt}': MISSING or ERROR ({str(e)})")
        
        # 4. Check API Whitelist
        from class_mgmt.class_mgmt import api
        print("API 'list_classes' found in module: YES")
        
        # 5. Check Recent Error Logs
        print("\n=== Recent Error Logs (Top 3) ===")
        logs = frappe.get_all("Error Log", 
                             fields=["name", "method", "error", "creation"], 
                             order_by="creation desc", 
                             limit=3)
        for log in logs:
            print(f"--- {log.name} ({log.creation}) ---")
            print(f"Method: {log.method}")
            print(f"Error: {log.error[:1000]}")
            print("-" * 30)

    except Exception as e:
        print(f"FATAL DIAGNOSTIC ERROR: {str(e)}")

if __name__ == "__main__":
    diagnose()
