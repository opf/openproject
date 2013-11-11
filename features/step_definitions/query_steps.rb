Given /^the [Pp]roject "([^\"]*)" has (\d+) [wW]ork [pP]ackage [qQ]uer(?:ies|y)? with(?: the following)?:$/ do |project, count, table|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    i = FactoryGirl.build(:query, :project => p)
    send_table_to_object(i, table)
    i.save
  end
end

Given /^the [Pp]roject "([^\"]*)" has (\d+) [wW]ork [pP]ackage [qQ]uer(?:ies|y)?$/ do |project, count|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    i = FactoryGirl.build(:query, :project => p)
    i.save
  end
end