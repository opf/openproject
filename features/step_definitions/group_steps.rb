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

Given /^there is 1 group with the following:$/ do |table|
  group = FactoryGirl.build(:group)

  send_table_to_object group, table, { :name => Proc.new { |group, name| group.lastname = name } }
end

Given /^the group "(.+)" is a "(.+)" in the project "(.+)"$/ do |group_name, role_name, project_identifier|
  steps %Q{ Given the principal "#{group_name}" is a "#{role_name}" in the project "#{project_identifier}" }
end

Given /^the group "(.+?)" has the following members:$/ do |name, table|
  group = Group.find_by_lastname(name)

  raise "No group with name #{name} found" unless group.present?

  user_names = table.raw.flatten

  users = User.find_all_by_login(user_names)

  not_found = user_names - users.map(&:login)

  raise "Could not find users with login: #{not_found}" if not_found.size > 0

  group.add_member!(users)
end

When /^I add the user "(.+)" to the group$/ do |user_login|
  user = User.find_by_login!(user_login)

  steps %Q{
    When I check "#{user.name}" within "#tab-content-users #users"
    And I press "Add" within "#tab-content-users"
  }
end

Given /^there is a group named "(.*?)" with the following members:$/ do |name, table|
  group = FactoryGirl.create(:group, :lastname => name)

  table.raw.flatten.each do |login|
    group.users << User.find_by_login!(login)
  end
end

When /^I delete "([^"]*)" from the group$/ do |login|
  user = User.find_by_login!(login)
  step %Q(I follow "Delete" within "#user-#{user.id}")
end

Given /^We have the group "(.*?)"/ do |name|
  group = FactoryGirl.create(:group, :lastname => name)
end

InstanceFinder.register(Group, Proc.new{ |name| Group.find_by_lastname(name) })
