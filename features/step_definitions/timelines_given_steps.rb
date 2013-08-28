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

Given /^the [pP]roject "([^\"]*)" has the parent "([^\"]*)"$/ do |child_name, parent_name|
  parent = Project.find_by_name(parent_name)
  child = Project.find_by_name(child_name)

  child.set_parent!(parent);
  child.save!
end

Given /^there are the following colors:$/ do |table|
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:color, type_attributes)
  end
end

Given /^I am working in the [tT]imeline "([^"]*)" of the project called "([^"]*)"$/ do |timeline_name, project_name|
  @project = Project.find_by_name(project_name)
  @timeline_name = timeline_name
end

Given /^there are the following planning element statuses:$/ do |table|
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:planning_element_status, type_attributes)
  end
end

Given /^there are the following reported project statuses:$/ do |table|
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:reported_project_status, type_attributes)
  end
end

Given /^there are the following project types:$/ do |table|
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:project_type, type_attributes)
  end
end

Given /^there are the following projects of type "([^"]*)":$/ do |project_type_name, table|
  table.raw.flatten.each do |name|
    step %Q{there is a project named "#{name}" of type "#{project_type_name}"}
  end
end

Given /^there are the following project associations:$/ do |table|
  table.map_headers! { |h| h.delete(' ').underscore }

  table.map_column!('project_a') { |name| Project.find_by_name!(name) }
  table.map_column!('project_b') { |name| Project.find_by_name!(name) }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:project_association, type_attributes)
  end
end

Given /^there are the following reportings:$/ do |table|
  table.map_headers! { |h| h.delete(' ').underscore }

  table.hashes.each do |attrs|
    attrs['project'] = Project.find_by_name!(attrs["project"])
    attrs['reporting_to_project'] = Project.find_by_name!(attrs["reporting_to_project"])
    FactoryGirl.create(:reporting, attrs)
  end
end

Given /^there is a timeline "([^"]*)" for project "([^"]*)"$/ do |timeline_name, project_name|
  project = Project.find_by_name(project_name)

  timeline = FactoryGirl.create(:timeline, :project_id => project.id, :name => timeline_name)
  timeline.options = {"initial_outline_expansion"=>["6"], "timeframe_end"=>"", "timeframe_start"=>"", "zoom_factor"=>["-1"], "exist"=>""}
  timeline.save!
end

Given /^the following types are enabled for projects of type "(.*?)"$/ do |project_type_name, type_name_table|
  project_type = ProjectType.find_by_name(project_type_name)
  projects = Project.where(:project_type_id => project_type.id)
  types = type_name_table.raw.flatten.map do |type_name|
    Type.find_by_name(type_name) || Factory.create(:type, :name => type_name)
  end

  projects.each do |project|
    project.types = types
    project.save
  end
end
