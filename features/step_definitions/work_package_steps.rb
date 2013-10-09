# encoding: utf-8
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

require "rack_session_access/capybara"

InstanceFinder.register(WorkPackage, Proc.new { |name| WorkPackage.find_by_subject(name) })
RouteMap.register(WorkPackage, "/work_packages")

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

  FactoryGirl.create :relation, from: from, to: to
end

Given /^user is already watching "(.*?)"$/  do |work_package_subject|
  work_package = WorkPackage.find_by_subject(work_package_subject)
  user = User.find(page.get_rack_session["user_id"])

  work_package.add_watcher user
end

Given(/^the work_package "(.+?)" is updated with the following:$/) do |subject, table|
  work_package = WorkPackage.find_by_subject(subject)
  except = {}

  except["type"] = lambda{|wp, value| wp.type = Type.find_by_name(value) if value }
  except["assigned_to"] = lambda{|wp, value| wp.assigned_to = User.find_by_login(value) if value}
  except["responsible"] = lambda{|wp, value| wp.responsible = User.find_by_login(value) if value}

  send_table_to_object(work_package, table, except)
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
