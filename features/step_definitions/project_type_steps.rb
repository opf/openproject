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

InstanceFinder.register(ProjectType, Proc.new { |name| ProjectType.find_by_name(name) })

Given /^the project(?: named "([^"]*)")? has no project type$/ do |name|
  project = get_project(name)
  project.update_attribute(:project_type_id, nil)
end

Given /^the project(?: named "([^"]*)")? is of the type "([^"]*)"$/ do |name, type_name|
  type_id = ProjectType.select(:id).find_by_name(type_name).id
  project = get_project(name)
  project.update_attribute(:project_type_id, type_id)
end

When /^I follow the edit link of the project type "([^"]*)"$/ do |project_type_name|
  type = ProjectType.find_by_name(project_type_name)

  href = Rails.application.routes.url_helpers.edit_project_type_path(type)

  click_link(type.name, :href => href)
end

