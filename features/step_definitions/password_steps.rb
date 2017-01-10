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

def parse_password_rules(str)
  str.sub(', and ', ', ').split(', ')
end

Given /^passwords must contain ([0-9]+) of ([a-z, ]+) characters$/ do |minimum_rules, rules|
  rules = parse_password_rules(rules)
  Setting.password_active_rules = rules
  Setting.password_min_adhered_rules = minimum_rules.to_i
end

Given /^passwords have a minimum length of ([0-9]+) characters$/ do |minimum_length|
  Setting.password_min_length = minimum_length
end

Given /^users are not allowed to reuse the last ([0-9]+) passwords$/ do |count|
  Setting.password_count_former_banned = count
end

def fill_change_password(old_password, new_password, confirmation = new_password)
  # use find and set with id to prevent ambiguous match I get with fill_in
  find('#password').set(old_password)

  fill_in('new_password', with: new_password)
  fill_in('new_password_confirmation', with: confirmation)
  click_link_or_button 'Save'
  @new_password = new_password
end

def change_password(old_password, new_password)
  visit '/my/password'
  fill_change_password(old_password, new_password)
end

Given /^I try to change my password from "([^\"]+)" to "([^\"]+)"$/ do |old, new|
  change_password(old, new)
end

When /^I try to set my new password to "(.+)"$/ do |password|
  visit '/my/password'
  change_password('adminADMIN!', password)
end

When /^I fill out the change password form$/ do
  fill_change_password('adminADMIN!', 'adminADMIN!New')
end

When /^I fill out the change password form with a wrong old password$/ do
  fill_change_password('wrong', 'adminADMIN!New')
end

When /^I fill out the change password form with a wrong password confirmation$/ do
  fill_change_password('adminADMIN!', 'adminADMIN!New', 'wrong')
end

Then /^the password change should succeed$/ do
  find('.notice').should have_content('success')
end

Then /^I should be able to login using the new password$/ do
  visit('/logout')
  login(@user.login, @new_password)
end

Then /^the password and confirmation fields should be empty$/ do
  find('#user_password').value.should be_empty
  find('#user_password_confirmation').value.should be_empty
end

Then /^the password and confirmation fields should be disabled$/ do
  find('#user_password').should be_disabled
  find('#user_password_confirmation').should be_disabled
end

Then /^the force password change field should be checked$/ do
  find('#user_force_password_change').should be_checked
end

Then /^the force password change field should be disabled$/ do
  find('#user_force_password_change').should be_disabled
end

Given /^I try to log in with user "([^"]*)"$/ do |login|
  step 'I go to the logout page'
  login(login, @new_password || 'adminADMIN!')
end

Given /^I try to log in with user "([^"]*)" and a wrong password$/ do |login|
  step 'I go to the logout page'
  login(login, 'Wrong password')
end

Given /^I try to log in with user "([^"]*)" and the password sent via email$/ do |login|
  step 'I go to the logout page'
  login(login, assigned_password_from_last_email)
end

When /^I activate the ([a-z, ]+) password rules$/ do |rules|
  rules = parse_password_rules(rules)
  # ensure checkboxes are loaded, 'all' doesn't wait
  should have_selector(:xpath, "//input[@id='settings_password_active_rules_' and @value='#{rules.first}']")

  all(:xpath, "//input[@id='settings_password_active_rules_']").each do |checkbox|
    checkbox.set(false)
  end
  rules.each do |rule|
    find(:xpath, "//input[@id='settings_password_active_rules_' and @value='#{rule}']").set(true)
  end
end

def set_user_attribute(login, attribute, value)
  user = User.find_by login: login
  user.send((attribute.to_s + '=').to_sym, value)
  user.save
end

Given /^the user "(.+)" is(not |) forced to change his password$/ do |login, disable|
  set_user_attribute(login, :force_password_change, disable != 'not ')
end

Given /^I use the first existing token to request a password reset$/ do
  token = Token.first
  visit account_lost_password_path(token: token.value)
end
