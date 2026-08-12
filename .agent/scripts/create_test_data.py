import frappe
from frappe.utils import add_days, today
import traceback

print("===== CREATING TEST DATA =====")
try:
    # 1. LMS Course
    course_name_hint = "course-101-demo"
    if not frappe.db.exists("LMS Course", {"name": course_name_hint}) and not frappe.db.exists("LMS Course", {"title": "React Dashboard 101"}):
        doc = frappe.get_doc({
            "doctype": "LMS Course",
            "name": course_name_hint,
            "title": "React Dashboard 101",
            "published": 1,
            "upcoming": 0,
            "currency": "USD"
        }).insert(ignore_permissions=True, ignore_mandatory=True)
        course_name = doc.name
        print("Created LMS Course:", course_name)
    else:
        course_name = frappe.db.get_value("LMS Course", {"title": "React Dashboard 101"}, "name")
        if not course_name:
            course_name = course_name_hint
        
        # Create some LMS Lessons
        for i in range(1, 4):
            # Chapter is required in LMS
            chapter = f"chapter-{course_name}-01"
            if not frappe.db.exists("Course Chapter", chapter):
                 frappe.get_doc({"doctype": "Course Chapter", "name": chapter, "title": "Introduction", "course": course_name}).insert(ignore_permissions=True, ignore_mandatory=True)
            
            frappe.get_doc({
                "doctype": "Course Lesson",
                "chapter": chapter,
                "title": f"Lesson {i} - Basics",
                "body": "Lesson content"
            }).insert(ignore_permissions=True, ignore_mandatory=True)
            print(f"Created Lesson {i} for course {course_name}")

    # 2. LMS Batch
    batch_title = "Batch 2026 Q2"
    batch = frappe.db.get_value("LMS Batch", {"title": batch_title}, "name")
    if not batch:
        doc = frappe.get_doc({
            "doctype": "LMS Batch",
            "title": batch_title,
            "course": course_name,
            "start_date": today(),
            "end_date": add_days(today(), 90),
            "published": 1
        }).insert(ignore_permissions=True, ignore_mandatory=True)
        batch = doc.name
        print("Created LMS Batch:", batch)

    # 3. EC Class
    class_name = "Class A - Spring 2026"
    class_id = frappe.db.get_value("EC Class", {"class_name": class_name}, "name")
    if not class_id:
        doc = frappe.get_doc({
            "doctype": "EC Class",
            "class_name": class_name,
            "course": course_name,
            "frappe_batch_id": batch,
            "status": "active",
            "schedule_config": '{"days": ["Wed", "Fri"], "start_time": "10:00:00", "end_time": "11:30:00", "start_date": "2026-04-01", "end_date": "2026-06-30"}',
            "description": "Demonstration class for testing the dashboard"
        })
        frappe.flags.ignore_batch_creation = True
        doc.insert(ignore_permissions=True, ignore_mandatory=True)
        frappe.flags.ignore_batch_creation = False
        class_id = doc.name
        print("Created EC Class:", class_id)
        
    print("Test data creation script complete. Class ID:", class_id)
    
    # 4. Generate Sessions using the api
    from class_mgmt.api import generate_sessions
    try:
        generate_sessions(class_id)
        print("Generated class sessions successfully.")
    except Exception as e:
        print("Note: Could not generate sessions automatically.", e)

    frappe.db.commit()
except Exception as e:
    print("ERROR DURING DATA CREATION")
    traceback.print_exc()

print("===== DONE =====")
