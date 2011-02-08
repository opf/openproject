Given /^there is 1 [Mm]eeting in project "(.+)" created by "(.+)" with:$/ do |project,user,table|
  m = Factory.build(:meeting)
  m.project = Project.find_by_name(project)
  m.author  = User.find_by_login(user)
  send_table_to_object(m, table)
end