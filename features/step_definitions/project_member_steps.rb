#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

def filter_user_by_login login
  # method to be overridden by plugins
  user = User.find_by_login(login)

  steps %Q{ When I fill in "principal_search" with "#{user.name}"
            And I wait for the AJAX requests to finish }
end

When /^I check the role "(.+?)" for the project member "(.+?)"$/ do |role_name, user_login|
  role = Role.find_by_name(role_name)

  member = member_for_login user_login

  steps %Q{When I check "member_role_ids_#{role.id}" within "#member-#{member.id}"}
end

Then /^the project member "(.+?)" should not be in edit mode$/ do |user_login|
  member = member_for_login user_login

  page.find("#member-#{member.id}-roles-form").should_not be_visible
end

Then /^the project member "(.+?)" should have the role "(.+?)"$/ do |user_login, role_name|
  member = member_for_login user_login

  steps %Q{Then I should see "#{role_name}" within "#member-#{member.id}-roles"}
end

When /^I follow the delete link of the project member "(.+?)"$/ do |login_name|
  member = member_for_login login_name

  steps %Q{When I follow "Delete" within "#member-#{member.id}"}
end

When /^I go to the project member settings of the project(?: called) "(.+?)"$/ do |project_name|
  steps %Q{
    When I go to the settings page of the project called "#{project_name}"
    And I click on "tab-members"
  }
end

When /^I add the principal "(.+)" as a member with the roles:$/ do |principal_name, roles_table|
  steps %Q{ When I check "#{principal_name}" within "#tab-content-members" }

  roles_table.raw.flatten.each do |role_name|
    steps %Q{ When I check "#{role_name}" within "#tab-content-members .splitcontentright" }
  end

  steps %Q{ When I press "Add" within "#tab-content-members .splitcontentright" }
end

Then /^I should see the principal "(.+)" as a member with the roles:$/ do |principal_name, roles_table|
  principal = InstanceFinder.find(Principal, principal_name)

  steps %Q{ Then I should see "#{principal.name}" within "#tab-content-members .members" }

  found_roles = page.find(:xpath, "//tr[contains(concat(' ',normalize-space(@class),' '),' member ')][contains(.,'#{principal.name}')]").find(:css, "td.roles span").text.split(",").map(&:strip)

  found_roles.should =~ roles_table.raw.flatten
end

Then /^I should not see the principal "(.+)" as a member$/ do |principal_name|
  principal = InstanceFinder.find(Principal, principal_name)

  steps %Q{ Then I should not see "#{principal.name}" within "#tab-content-members .members" }
end

When /^I filter for the user "(.+?)"$/ do |login|
  filter_user_by_login login
end

def member_for_login principal_name
  principal = InstanceFinder.find(Principal, principal_name)

  sleep 1

  #the assumption here is, that there is only one project
  principal.members.first
end

