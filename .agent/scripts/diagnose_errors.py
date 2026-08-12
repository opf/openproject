import frappe

def diagnose():
    frappe.connect()
    print("Checking Error Logs...")
    logs = frappe.get_all("Error Log", 
                         fields=["name", "method", "error", "creation"], 
                         order_by="creation desc", 
                         limit=5)
    for log in logs:
        print(f"--- {log.name} ({log.creation}) ---")
        print(f"Method: {log.method}")
        print(f"Error: {log.error[:500]}...")
        print("-" * 30)

if __name__ == "__main__":
    diagnose()
