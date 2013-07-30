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

When(/^I create a new enumeration with the following:$/) do |table|
  attributes = table.rows_hash

  type = activity_type_from_string(attributes['type'])

  visit new_enumeration_path(:type => type)

  fill_in 'enumeration_name', :with => attributes['name']

  click_button(I18n.t(:button_create))
end

Then(/^I should see the enumeration:$/) do |table|
  attributes = table.rows_hash

  type = activity_type_from_string(attributes['type'])

  # as the html is not structured in any way we have to look for the first
  # h3 that contains the heading for the activity we are interested in
  # and then the td within the directly following table
  should have_selector("h3:contains('#{i18n_for_activity_type(type)}') + table td",
                       :text => attributes['name'])
end

def activity_type_from_string(string)
  case string.gsub(/\s/,"_").camelcase
  when "Activity", "TimeEntryActivity"
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
