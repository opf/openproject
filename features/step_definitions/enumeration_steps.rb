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

When(/^I create a new enumeration with the following:$/) do |table|
  attributes = table.rows_hash

  type = activity_type_from_string(attributes['type'])

  visit new_enumeration_path(type: type)

  fill_in 'enumeration_name', with: attributes['name']

  click_button(I18n.t(:button_create))
end

Then(/^I should see the enumeration:$/) do |table|
  attributes = table.rows_hash

  type = activity_type_from_string(attributes['type'])

  # as the html is not structured in any way we have to look for the first
  # h3 that contains the heading for the activity we are interested in
  # and then the td within the directly following table
  selector = "h3:contains('#{i18n_for_activity_type(type)}') + .generic-table--container table td"
  should have_selector(selector, text: attributes['name'])
end

def activity_type_from_string(string)
  case string.gsub(/\s/, '_').camelcase
  when 'Activity', 'TimeEntryActivity'
    TimeEntryActivity
  else
    raise "Don't know this enumeration yet"
  end
end

def i18n_for_activity_type(type)
  if type == TimeEntryActivity
    I18n.t(:enumeration_activities)
  else
    raise "Don't know this enumeration yet"
  end
end
