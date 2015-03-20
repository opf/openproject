#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

[CustomField, WorkPackageCustomField].each do |const|
  InstanceFinder.register(const, Proc.new { |name| const.find_by_name(name) })
  RouteMap.register(const, '/custom_fields')
end

Given /^the following (user|issue|work package) custom fields are defined:$/ do |type, table|
  type = (type.gsub(' ', '_') + '_custom_field').to_sym

  as_admin do
    table.hashes.each_with_index do |r, _i|
      attr_hash = { name: r['name'],
                    field_format: r['type'] }

      attr_hash[:possible_values] = r['possible_values'].split(',').map(&:strip) if r['possible_values']
      attr_hash[:is_required] = (r[:required] == 'true') if r[:required]
      attr_hash[:editable] = (r[:editable] == 'true') if r[:editable]
      attr_hash[:visible] = (r[:visible] == 'true') if r[:visible]
      attr_hash[:is_filter] = (r[:is_filter] == 'true') if r[:is_filter]
      attr_hash[:default_value] = r[:default_value] ? r[:default_value] : nil
      attr_hash[:is_for_all] = r[:is_for_all] || true

      FactoryGirl.create type, attr_hash
    end
  end
end

Given /^the user "(.+?)" has the user custom field "(.+?)" set to "(.+?)"$/ do |login, field_name, value|
  user = User.find_by_login(login)
  custom_field = UserCustomField.find_by_name(field_name)

  user.custom_values.build(custom_field: custom_field, value: value)
  user.save!
end

Given /^the work package "(.+?)" has the custom field "(.+?)" set to "(.+?)"$/ do |wp_name, field_name, value|
  wp = InstanceFinder.find(WorkPackage, wp_name)
  custom_field = InstanceFinder.find(WorkPackageCustomField, field_name)

  custom_value = wp.custom_values.detect { |cv| cv.custom_field_id == custom_field.id }

  if custom_value
    custom_value.value = value
  else
    wp.custom_values.build(custom_field: custom_field, value: value)
  end

  wp.save!
end

Given /^the work package "(.+?)" has the custom user field "(.+?)" set to "(.+?)"$/ do |wp_name, field_name, username|
  user = User.find_by_login(username)
  steps %{
    Given the work package "#{wp_name}" has the custom field "#{field_name}" set to "#{user.id}"
  }
end

Given(/^the custom field "(.*?)" is enabled for the project "(.*?)"$/) do |field_name, project_name|
  custom_field = WorkPackageCustomField.find_by_name(field_name)
  project = Project.find_by_name(project_name)

  project.work_package_custom_fields << custom_field
  project.save!
end

Given(/^the custom field "(.*?)" is disabled for the project "(.*?)"$/) do |field_name, project_name|
  custom_field = WorkPackageCustomField.find_by_name(field_name)
  project = Project.find_by_name(project_name)

  project.work_package_custom_fields.delete custom_field
end

Given /^the custom field "(.+)" is( not)? summable$/ do |field_name, negative|
  custom_field = WorkPackageCustomField.find_by_name(field_name)

  Setting.work_package_list_summable_columns = negative ?
                                          Setting.work_package_list_summable_columns - ["cf_#{custom_field.id}"] :
                                          Setting.work_package_list_summable_columns << "cf_#{custom_field.id}"
end

Given /^the custom field "(.*?)" is activated for type "(.*?)"$/ do |field_name, type_name|
  custom_field = WorkPackageCustomField.find_by_name(field_name)
  type = Type.find_by_name(type_name)
  custom_field.types << type
end

Given /^there are no custom fields$/ do
  CustomField.destroy_all
end
