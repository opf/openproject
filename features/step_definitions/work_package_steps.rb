Given /^the work package "(.*?)" has the following children:$/ do |work_package_subject, table|
  parent = WorkPackage.find_by_subject(work_package_subject)
  
  table.raw.flatten.each do |child_subject|
    child = WorkPackage.find_by_subject(child_subject)

    if child.is_a? Issue
      child.parent_issue_id = parent.id
    elsif child.is_a? PlanningElement
      child.parent_id = parent.id
    end

    child.save
  end
end
