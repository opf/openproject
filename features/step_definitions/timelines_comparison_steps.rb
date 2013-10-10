#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

Given(/^there are the following work packages were added "(.*?)"(?: in project "([^"]*)")?:$/) do |time, project_name, table|
  project = get_project(project_name)

  #TODO provide better time support with some gem that can parse this:
  case time
  when "three weeks ago"
    target_time = 3.weeks.ago
  else
    target_time = Time.now
  end
  Timecop.travel(target_time)

  create_work_packages_from_table table, project

  # Ensure timecop returns after each scenario
  Support::ResetTimecop.reset_after
end

Given(/^the work package "(.*?)" was changed "(.*?)" to:$/) do |name, time, table|
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }

  #TODO provide better time support with some gem that can parse this:
  case time
  when "one week ago"
    target_time = 1.weeks.ago
  when "two weeks ago"
    target_time = 2.weeks.ago
  else
    target_time = Time.now
  end
  Timecop.travel(target_time)

  #TODO provide generic support for all possible values.
  work_package = WorkPackage.find_by_subject(name)
  work_package.subject = table.hashes.first[:subject]
  work_package.start_date = table.hashes.first[:start_date]
  work_package.due_date = table.hashes.first[:due_date]
  work_package.save!

  # Ensure timecop returns after each scenario
  Support::ResetTimecop.reset_after
end

When(/^I set the timeline to compare "(.*?)" to "(.*?) days ago"$/) do |first_time, second_time|
  steps %Q{
    When I edit the settings of the current timeline
    And I start debugging
  }

  page.should have_selector("#timeline_options_vertical_planning_elements", :visible => false)

  page.execute_script("jQuery('#timeline_options_vertical_planning_elements').val('#{planning_element.id}')")
  page.execute_script("jQuery('#content form').submit()")
end

Then(/^I should see the work package "(.*?)" has not moved$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^I should see the work package "(.*?)" has moved$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^I should not see the work package "(.*?)"$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end
