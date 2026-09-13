import frappe
from class_mgmt.api import get_session_enrollment, get_class_dashboard
import json
import sys

def test_slice_9():
    try:
        # 1. Find a session
        sessions = frappe.get_all("EC Class Session", limit=1)
        if not sessions:
            print("No sessions found")
            return
        
        session_id = sessions[0].name
        print(f"Testing Session: {session_id}")
        
        # 2. Test 9.1: Student Enrollment API
        print("\n--- 9.1 Verification (Student Enrollment API) ---")
        enrollment = get_session_enrollment(session_id)
        print(f"Enrollment count: {len(enrollment)}")
        if enrollment:
            first = enrollment[0]
            print(f"First student sample: {json.dumps(first, indent=2)}")
            
            # Verify 9.1 Success Criteria
            has_metadata = "full_name" in first and "user_image" in first
            print(f"9.1 Metadata Enriched: {'PASS' if has_metadata else 'FAIL'}")

        # 3. Test 9.4: Dashboard Enrichment (Bulk KPIs)
        print("\n--- 9.4 Verification (Timeline KPIs) ---")
        class_id = frappe.db.get_value("EC Class Session", session_id, "class")
        dashboard = get_class_dashboard(class_id)
        
        # Check sessions
        target_session = next((s for s in dashboard["all_sessions"] if s["name"] == session_id), None)
        if target_session:
            summary = target_session.get("attendance_summary", {})
            print(f"Attendance Summary for {session_id}: {json.dumps(summary, indent=2)}")
            
            # Verify 9.4 Success Criteria
            has_stats = "present_count" in summary and "total_enrolled" in summary
            print(f"9.4 Dashboard KPIs Enriched: {'PASS' if has_stats else 'FAIL'}")
        else:
            print(f"Error: Session {session_id} not found in dashboard for class {class_id}")

    except Exception as e:
        print(f"Error during verification: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    # Initialize frappe
    frappe.init(site="frappe.local")
    frappe.connect()
    try:
        test_slice_9()
    finally:
        frappe.destroy()
