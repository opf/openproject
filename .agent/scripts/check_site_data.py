print("----- START -----")
try:
    print("Courses: ", frappe.get_all("LMS Course", fields=["name", "title"], limit=5))
except Exception as e:
    print("No courses: ", e)

try:
    print("Batches: ", frappe.get_all("LMS Batch", fields=["name", "title"], limit=5))
except Exception as e:
    print("No batches: ", e)

try:
    print("Classes: ", frappe.get_all("EC Class", fields=["name", "class_name", "status"], limit=5))
except Exception as e:
    print("No classes: ", e)
print("----- END -----")
