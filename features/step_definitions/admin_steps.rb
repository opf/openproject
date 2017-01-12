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

Then /^I should see membership to the project "(.+)" with the roles:$/ do |project, roles_table|
  project = Project.like(project).first
  steps %{ Then I should see "#{project.name}" within "#tab-content-memberships .memberships" }
  tab = page.find('#tab-content-memberships .memberships')

  roles_table.raw.flatten.each do |role_name|
    expect(tab.find('tr', text: project.name)).to have_selector('td.roles span', text: role_name)
  end
end

Then /^I should not see membership to the project "(.+)"$/ do |project|
  project = Project.like(project).first
  begin
    page.find(:css, '#tab-content-memberships .memberships')
    steps %{ Then I should not see "#{project.name}" within "#tab-content-memberships .memberships" }
  rescue Capybara::ElementNotFound
    steps %{ Then I should see "This user is currently not a member of a project." within "#tab-content-memberships" }
  end
end

Then /^I check the role "([^"]+)"$/ do |role|
  role = Role.like(role).first
  steps %{And I check "membership_role_ids_#{role.id}"}
end

When /^I delete membership to project "(.*?)"$/ do |project|
  project = Project.like(project).first
  page.find(:css, '#tab-content-memberships .memberships').find(:xpath, "//tr[contains(.,'#{project.name}')]").find(:css, '.icon-remove').click
end

When /^I edit membership to project "(.*?)" to contain the roles:$/ do |project, roles_table|
  project = Project.like(project).first
  steps %{ Then I should see "#{project.name}" within "#tab-content-memberships .memberships" }

  # Click 'Edit'
  page.find(:css, '#tab-content-memberships .memberships').find(:xpath, "//tr[contains(.,'#{project.name}')]").find(:css, '.icon-edit').click

  roles_table.raw.flatten.map { |r| Role.like(r).first }.each do |role|
    checkbox = page.find(:css, '#tab-content-memberships .memberships').find(:xpath, "//tr[contains(.,'#{project.name}')]//input[@type='checkbox'][@value='#{role.id}']")
    checkbox.click unless checkbox.checked?
  end
  steps %{ And I click "Change" within "#tab-content-memberships .memberships" }
end
