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

Given /^the rest api is enabled$/ do
  Setting.rest_api_enabled = "1"
end

Given /^the following languages are available:$/ do |table|
  Setting.available_languages += table.raw.map(&:first)
end

#Given /^the "(.+?)" setting is set to (true|false)$/ do |name, trueish|
#  Setting[name.to_sym] = (trueish == "true" ? "1" : "0")
#end

Given /^the "(.+?)" setting is set to (.+)$/ do |name, value|
  value = case value
          when "true"
            "1"
          when "false"
            "0"
          else
            value
          end

  value = value.to_i if Setting.available_settings[name]["format"] == "int"

  Setting[name.to_sym] = value
end

Then /^the "(.+?)" setting should be (true|false)$/ do |name, trueish|
  Setting.send((name + "?").to_sym).should == (trueish == "true")
end

Given /^I save the settings$/ do
  click_button('Save')
end

##
# Setting-specific steps
#

#
# Directly write to Settings
#
Given /^users are blocked for ([0-9]+) minutes after ([0-9]+) failed login attempts$/ do |duration, attempts|
  Setting.brute_force_block_minutes = duration
  Setting.brute_force_block_after_failed_logins = attempts
end

Given /^we paginate after (\d+) items$/ do |per_page_param|
  Setting.per_page_options = "#{per_page_param}, 50, 100"
end

#
# Fill out settings forms
#
Given /^I set passwords to expire after ([0-9]+) days$/ do |days|
  visit '/settings?tab=authentication'
  fill_in('settings_password_days_valid', :with => days.to_s)
  step 'I save the settings'
end

