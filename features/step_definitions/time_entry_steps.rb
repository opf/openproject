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

Given(/^there is a time entry for "(.*?)" with (\d+) hours$/) do |subject, hours|
  work_package = WorkPackage.find_by(subject: subject)
  time_entry = FactoryBot.create(:time_entry, work_package: work_package, hours: hours, project: work_package.project)
end

Given(/^there is an activity "(.*?)"$/) do |name|
  FactoryBot.create(:time_entry_activity, name: name)
end

When(/^I log (\d+) hours with the comment "(.*?)"$/) do |hours, comment|
  click_link I18n.t(:button_log_time)
  fill_in TimeEntry.human_attribute_name(:hours), with: hours
  fill_in TimeEntry.human_attribute_name(:comment), with: comment
  select 'Development', from: 'Activity'
  click_button I18n.t(:button_save)
end

Then(/^I should see a time entry with (\d+) hours and comment "(.*)"$/) do |hours, comment|
  expect(page).to have_content("#{hours}.00")
  expect(page).to have_content(comment)
end

Then(/^I should (not )?see a total spent time of (\d+) hours$/) do |negative, hours|
  available = find('div.total-hours') rescue false

  if available || !negative
    within('div.total-hours') do
      element = find('span.hours-int')

      if negative
        expect(element).not_to have_content hours
      else
        expect(element).to have_content hours
      end
    end
  end
end

When(/^I update the first time entry with (\d+) hours and the comment "(.*?)"$/) do |hours, comment|
  click_link I18n.t('button_edit')
  fill_in TimeEntry.human_attribute_name(:hours), with: hours
  fill_in TimeEntry.human_attribute_name(:comment), with: comment
  click_button 'Save'
end
