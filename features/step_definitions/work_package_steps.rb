# encoding: utf-8

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

require "rack_session_access/capybara"

InstanceFinder.register(WorkPackage, Proc.new { |name| WorkPackage.find_by_subject(name) })
RouteMap.register(WorkPackage, "/work_packages")
RouteMap.register(Issue, "/work_packages")

Given /^the work package "(.*?)" has the following children:$/ do |work_package_subject, table|
  parent = WorkPackage.find_by_subject(work_package_subject)

  table.raw.flatten.each do |child_subject|
    child = WorkPackage.find_by_subject(child_subject)

    child.parent_id = parent.id

    child.save
  end
end

Given /^a relation between "(.*?)" and "(.*?)"$/ do |work_package_from, work_package_to|
  from = WorkPackage.find_by_subject(work_package_from)
  to = WorkPackage.find_by_subject(work_package_to)

  FactoryGirl.create :issue_relation, issue_from: from, issue_to: to
end

Given /^user is already watching "(.*?)"$/  do |work_package_subject|
  work_package = WorkPackage.find_by_subject(work_package_subject)
  user = User.find(page.get_rack_session["user_id"])

  work_package.add_watcher user
end

Given(/^the work_package "(.+?)" is updated with the following:$/) do |subject, table|
  work_package = WorkPackage.find_by_subject(subject)

  send_table_to_object(work_package, table)
end

When /^I fill in the id of work package "(.+?)" into "(.+?)"$/ do |wp_name, field_name|
  work_package = InstanceFinder.find(WorkPackage, wp_name)

  fill_in(field_name, :with => work_package.id)
end

Then /^the "(.+?)" field should contain the id of work package "(.+?)"$/ do |field_name, wp_name|
  work_package = InstanceFinder.find(WorkPackage, wp_name)

  should have_field(field_name, :with => work_package.id.to_s)
end

Then /^the work package "(.+?)" should be shown as the parent$/ do |wp_name|
  work_package = InstanceFinder.find(WorkPackage, wp_name)

  should have_css("tr.work-package", :text => work_package.to_s)
end

Then /^the work package should be shown with the following values:$/ do |table|
  table_attributes = table.raw.select do |k, v|
    !["Subject", "Type", "Description"].include?(k)
  end

  table_attributes.each do |key, value|
    label = find('th', :text => key)
    should have_css("td.#{label[:class]}", :text => value)
  end

  if table.rows_hash["Type"] || table.rows_hash["Subject"]
    expected_header = Regexp.new("#{table.rows_hash["Type"]}\\s?#\\d+: #{table.rows_hash["Subject"]}")

    should have_css("h2", :text => expected_header)
  end

  if table.rows_hash["Description"]
    should have_css(".description", :text => table.rows_hash["Description"])
  end
end
