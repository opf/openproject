import frappe
from frappe.utils import add_days, today

print("===== CREATING LMS BATCH =====")
try:
    doc = frappe.get_doc({
        "doctype": "LMS Batch",
        "title": "Debug Batch 2026",
        "course": "course-101-demo",
        "start_date": today(),
        "end_date": add_days(today(), 90),
        "published": 1
    })
    print(f"Set start_date: {doc.start_date}, end_date: {doc.end_date}")
    doc.insert(ignore_permissions=True, ignore_mandatory=True)
    print("Successfully created LMS Batch:", doc.name)
except Exception as e:
    import traceback
    traceback.print_exc()

print("===== DONE =====")
