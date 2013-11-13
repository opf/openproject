Then /^I open the context menu on the work packages:$/ do |table|
  elements = []
  table.raw.flatten.each do |subject_or_id|
    wp = WorkPackage.find_by_subject(subject_or_id) || WorkPackage.find_by_id(subject_or_id)
    element = page.find(:xpath, "//body//div[@id='content']//tr[@id='work_package-#{wp.id}']")
    element.find(:css, ".checkbox input").click && elements << element
  end
  right_click(elements.first)
end
