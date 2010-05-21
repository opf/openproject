Given /^the project "([^\"]+)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y)$/ do |project, count|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    ce = CostEntry.generate
    ce.project = p
    ce.issue = Issue.generate_for_project!(p)
    ce.save!
  end
end

Given /^there is 1 cost type with the following:$/ do |table|
  ct = CostType.generate
  send_table_to_object(ct, table)
end

Given /^the [Uu]ser "([^\"]*)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y)$/ do |user, count|  
  u = User.find_by_login user
  p = u.projects.last
  i = Issue.generate_for_project!(p)
  as_admin count do
    ce = CostEntry.spawn
    ce.user_id = u.id
    ce.project_id = p.id
    ce.issue = i
    ce.save!
  end
end

Given /^the project "([^\"]+)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y) with the following:$/ do |project, count, table|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    ce = CostEntry.generate
    ce.project = p
    send_table_to_object(ce, table)
    ce.save!
  end
end

Given /^the issue "([^\"]+)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y) with the following:$/ do |project, count, table|
  i = Issue.find(:last, :condition => ["subject = #{issue}"])
  as_admin count do
    ce = CostEntry.generate
    ce.project = p
    send_table_to_object(ce, table)
    ce.save!
  end
end

Given /^there is a standard cost control project named "([^\"]*)"$/ do |name|
  steps %Q{
    Given there is 1 project with the following:
      | Name | #{name} |
    And the project "#{name}" has 1 subproject
    And the role "Manager" may have the following rights:
      | View own cost entries |
    And there is a role "Controller"
    And the role "Controller" may have the following rights:
      | View own cost entries |
    And the role "Developer" may have the following rights:
      | View own cost entries |
    And the role "Reporter" may have the following rights:
      | Create issues |
    And there is a role "Supplier"
    And the role "Supplier" may have the following rights:
      | View own hourly rate |
      | View own cost entries |
    And there is 1 user with:
      | Login | manager |
		And the user "manager" is a "Manager" in the project "#{name}"
		And there is 1 user with:
      | Login | controller |
		And the user "controller" is a "Controller" in the project "#{name}"
		And there is 1 user with:
      | Login | developer |
		And the user "developer" is a "Developer" in the project "#{name}"
		And there is 1 user with:
      | Login | reporter |
		And the user "reporter" is a "Reporter" in the project "#{name}"
  }
end
