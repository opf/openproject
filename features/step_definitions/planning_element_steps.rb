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

Given (/^there are the following planning elements(?: in project "([^"]*)")?:$/) do |project_name, table|
  project = get_project(project_name)
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    status = PlanningElementStatus.find_by_name(type_attributes.delete("status_name"))
    responsible = User.find_by_login(type_attributes.delete("responsible"))
    planning_element_type = PlanningElementType.find_by_name(type_attributes.delete("planning_element_type"));

    factory = FactoryGirl.create(:planning_element, type_attributes.merge(:project_id => project.id))

    factory.reload

    factory.planning_element_status = status unless status.nil?
    factory.responsible = responsible unless responsible.nil?
    factory.planning_element_type = planning_element_type unless planning_element_type.nil?
    factory.save! if factory.changed?
  end
end
