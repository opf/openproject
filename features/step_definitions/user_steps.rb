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

InstanceFinder.register(User, Proc.new { |name| User.find_by_login(name) })

##
# Editing/creating users (admin UI)
#
#

When /^I create a new user$/ do
  visit '/users/new'
  fill_in('user_login', with: 'newbobby')
  fill_in('user_firstname', with: 'newbobby')
  fill_in('user_lastname', with: 'newbobby')
  fill_in('user_mail', with: 'newbobby@example.com')
end

When /^I edit the user "([^\"]*)"$/ do |user|
  user_id = User.find_by_login(user).id
  visit "/users/#{user_id}/edit"
end

When /^I assign the user "([^\"]*)" a random password$/ do |user|
  step "I edit the user \"#{user}\""
  step 'I check the assign random password to user field'
  step 'I save the user'
end

When /^I check the assign random password to user field$/ do
  check(I18n.t(:assign_random_password, scope: :user))
end

Given /^I save the user$/ do
  click_button('Save')
end

Given /^I save the new user$/ do
  click_button('Create', exact: true)
end

##
# Creating users (on the DB)
#
Given /^there is 1 [Uu]ser with(?: the following)?:$/ do |table|
  login = table.rows_hash[:Login].to_s + table.rows_hash[:login].to_s
  user = User.find_by_login(login) unless login.blank?

  if !user
    user = FactoryGirl.create(:user)
    user.pref
    user.password = user.password_confirmation = nil
  end

  modify_user(user, table)
end

Given /^the [Uu]ser "([^\"]*)" has:$/ do |user, table|
  u = User.find_by_login(user)
  raise "No such user: #{user}" unless u
  modify_user(u, table)
end

Given /^the [Uu]ser "([^\"]*)" has the following preferences$/ do |user, table|
  u = User.find_by_login(user)

  send_table_to_object(u.pref, table)
end

Given /^the user "([^\"]*)" is locked$/ do |user|
  User.find_by_login(user).lock!
end

Given /^the user "([^\"]*)" is registered and not activated$/ do |user|
  User.find_by_login(user).register!
end

Given /^the user "([^\"]*)" had too many recently failed logins$/ do |user|
  user = User.find_by_login(user)
  user.failed_login_count = 100
  user.last_failed_login_on = Time.now
  user.save
end

Given /^there are the following users:$/ do |table|
  table.raw.flatten.each do |login|
    FactoryGirl.create(:user, login: login)
  end
end

Given /^there is a user named "([^\"]+)"$/ do |user|
  steps %{
    Given there are the following users:
    | #{user} |
  }
end

Then /^there should be a user with the following:$/ do |table|
  expected = table.rows_hash

  user = User.find_by_login(expected['login'])

  user.should_not be_nil

  expected.each do |key, value|
    user.send(key).should == value
  end
end

Given 'journals are not being aggregated' do
  Setting.journal_aggregation_time_minutes = 0
end

##
# admin users list
#
When /^I filter the users list by status "([^\"]+)"$/ do |status|
  visit('/users')
  select(status, from: 'Status:')
  click_on "Apply"
end

Given(/^I click the (\w+) access key reset link$/) do |access_key_type|
  within '#access-token-table' do
    find('tr', text: "#{access_key_type} access key").click_link('Reset')
  end
end
