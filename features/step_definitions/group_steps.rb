#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Given /^there is 1 group with the following:$/ do |table|
  group = FactoryGirl.build(:group)

  send_table_to_object group, table,  name: Proc.new { |group, name| group.lastname = name }
end

Given /^the group "(.+)" is a "(.+)" in the project "(.+)"$/ do |group_name, role_name, project_identifier|
  steps %{ Given the principal "#{group_name}" is a "#{role_name}" in the project "#{project_identifier}" }
end

Given /^the group "(.+?)" has the following members:$/ do |name, table|
  group = Group.find_by(lastname: name)

  raise "No group with name #{name} found" unless group.present?

  user_names = table.raw.flatten

  users = User.where(login: user_names)

  not_found = user_names - users.map(&:login)

  raise "Could not find users with login: #{not_found}" if not_found.size > 0

  group.add_member!(users)
end

When /^I add the user "(.+)" to the group$/ do |user_login|
  user = User.find_by!(login: user_login)

  steps %{
    When I check "#{user.name}" within "#tab-content-users #users"
    And I press "Add" within "#tab-content-users"
  }
end

Given /^We have the group "(.*?)"/ do |name|
  group = FactoryGirl.create(:group, lastname: name)
end

Given /^there is a group named "(.*?)" with the following members:$/ do |name, table|
  group = FactoryGirl.create(:group, lastname: name)

  table.raw.flatten.each do |login|
    group.users << User.find_by!(login: login)
  end
end

When /^I delete "([^"]*)" from the group$/ do |login|
  user = User.find_by!(login: login)
  step %(I follow "Delete" within "#user-#{user.id}")
end

InstanceFinder.register(Group, Proc.new { |name| Group.find_by(lastname: name) })
