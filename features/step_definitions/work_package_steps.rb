#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'rack_session_access/capybara'

InstanceFinder.register(WorkPackage, Proc.new { |name| WorkPackage.find_by(subject: name) })
RouteMap.register(WorkPackage, '/work_packages')

Given /^the work package "(.*?)" has the following children:$/ do |work_package_subject, table|
  parent = WorkPackage.find_by(subject: work_package_subject)

  table.raw.flatten.each do |child_subject|
    child = WorkPackage.find_by(subject: child_subject)

    child.parent_id = parent.id

    child.save
  end
end

Given /^a relation between "(.*?)" and "(.*?)"$/ do |work_package_from, work_package_to|
  from = WorkPackage.find_by(subject: work_package_from)
  to = WorkPackage.find_by(subject: work_package_to)

  FactoryBot.create :relation, from: from, to: to
end

Given /^user is already watching "(.*?)"$/  do |work_package_subject|
  work_package = WorkPackage.find_by(subject: work_package_subject)
  user = User.find(page.get_rack_session['user_id'])

  work_package.add_watcher user
end

Given(/^the work_package "(.+?)" is updated with the following:$/) do |subject, table|
  work_package = WorkPackage.find_by(subject: subject)
  except = {}

  except['type'] = lambda { |wp, value| wp.type = ::Type.find_by(name: value) if value }
  except['assigned_to'] = lambda { |wp, value| wp.assigned_to = User.find_by_login(value) if value }
  except['responsible'] = lambda { |wp, value| wp.responsible = User.find_by_login(value) if value }

  send_table_to_object(work_package, table, except)
end

Given(/^the user "([^\"]+)" has the following queries by type in the project "(.*?)":$/) do |login, project_name, table|
  u = User.find_by login: login
  p = get_project(project_name)

  table.hashes.each_with_index do |t, _i|
    types = ::Type.where(name: t['type_value']).map { |type| type.id.to_s }
    query = p.queries.create(user_id: u.id, name: t['name'])
    query.filters.clear
    query.add_filter(:type_id, '=', types)
    query.save!
  end
end

Given(/^the user "([^\"]+)" has the following query menu items in the project "(.*?)":$/) do |login, project_name, table|
  u = User.find_by login: login
  p = get_project(project_name)

  table.hashes.each_with_index do |t, _i|
    query = p.queries.find_by name: t['navigatable']
    MenuItems::QueryMenuItem.create name: t['name'], title: t['title'], navigatable_id: query.id
  end
end

When /^the work package table has finished loading$/ do
  message <<-MESSAGE
    This is a safeguard to ensure that the work package table is loaded before performing actions
    on UI items that have not been fully loaded.

    It currently assumes that at least one filter is set, without the necessity of the filter being
    displayed.
  MESSAGE

  expect(page).to have_selector('.advanced-filters--filter', visible: false), message
end

When /^I fill in the id of work package "(.+?)" into "(.+?)"$/ do |wp_name, field_name|
  work_package = InstanceFinder.find(WorkPackage, wp_name)

  fill_in(field_name, with: work_package.id)
end

Then /^the "(.+?)" field should contain the id of work package "(.+?)"$/ do |field_name, wp_name|
  work_package = InstanceFinder.find(WorkPackage, wp_name)

  should have_field(field_name, with: work_package.id.to_s)
end

Then /^the work package "(.+?)" should be shown as the parent$/ do |wp_name|
  work_package = InstanceFinder.find(WorkPackage, wp_name)

  step "I open the work package tab \"Relations\""
  within('.tabcontent') do
    should have_content(work_package.to_s)
  end
end

Then /^the work package should be shown with the following values:$/ do |table|
  table_attributes = table.raw.select { |k, _v|
    !['Subject', 'Description'].include?(k)
  }

  table_attributes.each do |key, value|
    label = find('div.attributes-key-value--key', text: key)
    should have_css("div.#{label[:class].split(' ').last}", text: value)
  end

  if table.rows_hash['Subject']
    subject_field = find(".work-packages--details--subject input")
    expect(subject_field.value).to eq(table.rows_hash['Subject'])
  end

  if table.rows_hash['Description']
    should have_css('.work-packages--details--description', text: table.rows_hash['Description'])
  end
end

Then(/^the attribute "(.*?)" of work package "(.*?)" should be "(.*?)"$/) do |attribute, wp_name, value|
  wp = WorkPackage.find_by(subject: wp_name)
  wp ||= WorkPackages.where('subject like ?', wp_name).to_sql
  wp.send(attribute).to_s.should == value
end

When /^I open the work package tab "(.+?)"$/ do |tab_label|
  within('#tabs') do
    click_link tab_label
  end
end

When /^I click the edit work package button$/ do
  within('#toolbar-items') do
    find('button[title=Edit]').click
  end
end

When /^I click the watch work package button$/ do
  within('#toolbar-items') do
    find('#watch-button').click
  end
end

When /^I click the unwatch work package button$/ do
  within('#toolbar-items') do
    find('#unwatch-button').click
  end
end

When /^I fill in a comment with "(.+?)"$/ do |comment|
  # Using the "I click on "..." step does not work for some reason

  find('.work-packages--activity--add-comment .inplace-editing--trigger-link').click

  steps %{
    Then I fill in "value" with "#{comment}" within ".work-packages--activity--add-comment"
  }
end

When /^I preview the comment to be added and see "(.+?)"$/ do |comment|
  steps %{
    And I click on "Preview" within ".work-packages--activity--add-comment"
    And I should see "#{comment}" within ".work-packages--activity--add-comment .inplace-edit--preview"
  }
end

When /^I should see the comment "(.+?)"$/ do |comment|
  steps %{
    And I should see "#{comment}" within ".work-package-details-activities-list"
  }
end

When /^I preview the "(.+?)" and see "(.+?)"$/ do |field_name, text|
  steps %{
    And I click on "Preview" within ".work-packages--details--#{field_name}"
    And I should see "#{text}" within ".work-packages--details--#{field_name} .-preview"
  }
end

When /^I click to see all work package attributes$/ do
  find('a', text: I18n.t('js.label_show_attributes')).click
end
