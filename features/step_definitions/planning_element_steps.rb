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

    [
      ["planning_element_status", PlanningElementStatus],
      ["responsible", User],
      ["assigned_to", User],
      ["type", Type],
      ["fixed_version", Version],
      ["priority", IssuePriority],
      ["status", IssueStatus],
      ["parent", WorkPackage]
    ].each do |key, const|
      if type_attributes[key].present?
        type_attributes[key] = InstanceFinder.find(const, type_attributes[key])
      else
        type_attributes.delete(key)
      end
    end

    unless type_attributes.has_key? :type
      type_attributes[:type] = Type.find(:first, conditions: { is_standard: true })
    end

    factory = FactoryGirl.create(:planning_element, type_attributes.merge(:project_id => project.id))
  end
end
