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

When /^I edit the user "([^\"]*)"$/ do |user|
  user_id = User.find_by_login(user).id
  visit "/users/#{user_id}/edit"
end

When /^I (activate_and_reset_failed_logins|lock|unlock) the user "([^\"]*)"$/ do |action, user|
  button_title = {
    'activate' => 'Unlock and reset failed logins'
  }
  click_button()
end

Given /^there is 1 [Uu]ser with(?: the following)?:$/ do |table|
  login = table.rows_hash[:Login].to_s + table.rows_hash[:login].to_s
  user = User.find_by_login(login) unless login.blank?

  if !user
    user = FactoryGirl.create(:user)
    user.password = user.password_confirmation = nil
  end

  modify_user(user, table)
end

Given /^the [Uu]ser "([^\"]*)" has:$/ do |user, table|
  u = User.find_by_login(user)
  raise "No such user: #{user}" unless u
  modify_user(u, table)
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
    FactoryGirl.create(:user, :login => login)
  end
end

Given /^there is a user named "([^\"]+)"$/ do |user|
  steps %Q{
    Given there are the following users:
    | #{user} |
  }
end

Then /^there should be a user with the following:$/ do |table|
  expected = table.rows_hash

  user = User.find_by_login(expected["login"])

  user.should_not be_nil

  expected.each do |key, value|
    user.send(key).should == value
  end
end

##
# admin users list
#
When /^I filter the users list by status "([^\"]+)"$/ do |status|
  visit('/users')
  select(status, :from => 'Status:')
end
