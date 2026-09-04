import os
import sys
import frappe

def main():
    frappe.init(site="frappe.local")
    frappe.connect()
    
    # Just check if we can get the schedule days
    doc = frappe.get_doc("EC Class", "CLS-0001")
    print("Class:", doc.class_name)
    print("Start Date:", doc.start_date)
    print("End Date:", doc.end_date)
    print("Start Time:", doc.start_time)
    print("End Time:", doc.end_time)
    
    # Set some days
    doc.day_mon = 1
    doc.day_wed = 1
    doc.start_date = "2024-06-01"
    doc.end_date = "2024-06-30"
    doc.start_time = "09:00:00"
    doc.end_time = "11:00:00"
    doc.save()
    frappe.db.commit()
    
    print("Schedule Days:", doc.get_schedule_days())
    
    # Generate sessions
    from class_mgmt.api import generate_sessions
    frappe.session.user = "Administrator" # to bypass permission
    res = generate_sessions("CLS-0001")
    print("Generated Sessions:", res)

if __name__ == "__main__":
    main()
