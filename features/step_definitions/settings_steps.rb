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

Given /^the rest api is enabled$/ do
  Setting.rest_api_enabled = '1'

  Support::Cleanup.to_clean Support::ClearCache.clear
end

Given /^the following languages are available:$/ do |table|
  Setting.available_languages += table.raw.map(&:first)

  Support::Cleanup.to_clean Support::ClearCache.clear
end

# Given /^the "(.+?)" setting is set to (true|false)$/ do |name, trueish|
#  Setting[name.to_sym] = (trueish == "true" ? "1" : "0")
# end

Given /^the "(.+?)" setting is set to (.+)$/ do |name, value|
  value = case value
          when 'true'
            '1'
          when 'false'
            '0'
          else
            value
          end

  value = value.to_i if Setting.available_settings[name]['format'] == 'int'

  Setting[name.to_sym] = value

  Support::ClearCache.clear_after
end

Then /^the "(.+?)" setting should be (true|false)$/ do |name, trueish|
  Setting.send((name + '?').to_sym).should == (trueish == 'true')
end

Given /^I save the settings$/ do
  click_button('Save')

  Support::ClearCache.clear_after
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

  Support::ClearCache.clear_after
end

Given /^we paginate after (\d+) items$/ do |per_page_param|
  Setting.per_page_options = "#{per_page_param}, 50, 100"

  Support::ClearCache.clear_after
end

#
# Fill out settings forms
#
Given /^I set passwords to expire after ([0-9]+) days$/ do |days|
  visit '/settings?tab=authentication'
  fill_in('settings_password_days_valid', with: days.to_s)
  step 'I save the settings'

  Support::ClearCache.clear_after
end

module Support
  module ClearCache
    def self.clear_after
      Support::Cleanup.to_clean do
        Rails.cache.clear
      end
    end
  end
end
