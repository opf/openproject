#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

def get_timeline_row_by_name(name)
  find('a', text: name).find(:xpath, './ancestor::tr')
end

def get_timeline_cell(name, valueName)
  wpRow = get_timeline_row_by_name(name)
  index = get_timelines_row_number_by_name(valueName)

  wpRow.all('td')[index]
end

def get_timelines_row_number_by_name(name)
  result = -1

  th = find('table.tl-main-table').find(:xpath, "./thead/tr/th[text()='#{name}']")
  ths = find('table.tl-main-table').all(:xpath, './thead/tr/th')

  for i in 0..ths.length do
    if  ths[i] == th
      result = i
      break
    end
  end

  result
end

Given(/^there are the following work packages were added "(.*?)"(?: in project "([^"]*)")?:$/) do |time, project_name, table|
  project = get_project(project_name)

  # TODO provide better time support with some gem that can parse this:
  case time
  when 'three weeks ago'
    target_time = 3.weeks.ago
  else
    target_time = Time.now
  end
  Timecop.freeze(target_time) do
    create_work_packages_from_table table, project
  end
end

Given(/^the work package "(.*?)" was changed "(.*?)" to:$/) do |name, time, table|
  table = table.map_headers { |header| header.underscore.gsub(' ', '_') }

  # TODO provide better time support with some gem that can parse this:
  case time
  when 'one week ago'
    target_time = 1.weeks.ago
  when 'two weeks ago'
    target_time = 2.weeks.ago
  when 'three weeks ago'
    target_time = 3.weeks.ago
  else
    target_time = Time.now
  end

  Timecop.freeze(target_time) do

    timeline = WorkPackage.find_by_subject(name)
    table.hashes.first.each do | key, value |
      timeline[key] = value
    end

    timeline.save!

  end
end

When(/^I set the timeline to compare "now" to "(.*?) days ago"$/) do |time|
  steps %{
    When I edit the settings of the current timeline
  }

  page.should have_selector('#timeline_options_vertical_planning_elements', visible: false)
  page.execute_script("jQuery('#timeline_options_comparison_relative').attr('checked', 'checked')")
  page.execute_script("jQuery('#timeline_options_compare_to_relative').val('#{time}')")
  page.execute_script("jQuery('#timeline_options_compare_to_relative_unit').val(0)")
  page.execute_script("jQuery('#content form').submit()")
end

Then(/^I should see the work package "(.*?)" has not moved$/) do |name|
  row = get_timeline_row_by_name(name)
  row.should_not have_selector('.tl-icon-changed')
end

Then(/^I should see the work package "(.*?)" has moved$/) do |name|
  row = get_timeline_row_by_name(name)
  row.should have_selector('.tl-icon-changed')
end

Then(/^I should see the work package "(.*?)" has not changed "(.*?)"$/) do |name, column_name|
  expect(get_timeline_cell(name, column_name)).to have_no_css('.tl-icon-changed')
end

Then(/^I should see the work package "(.*?)" has changed "(.*?)"$/) do |name, column_name|
  expect(get_timeline_cell(name, column_name)).to have_css('.tl-icon-changed')
end
