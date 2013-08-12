Given /^the [Pp]roject "([^\"]*)" has (\d+) [Dd]ocument with(?: the following)?:$/ do |project, count, table|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    d = Document.spawn
    d.project = p
    d.category = DocumentCategory.first
    d.save!
    send_table_to_object(d, table)
  end
end
