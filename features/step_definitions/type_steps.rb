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

# change from symbol to constant once namespace is removed

InstanceFinder.register(Type, Proc.new { |name| Type.find_by_name(name) })

RouteMap.register(Type, "/types")

Given /^the following types are enabled for the project called "(.*?)":$/ do |project_name, type_name_table|
  types = type_name_table.raw.flatten.map do |type_name|
    Type.find_by_name(type_name) || FactoryGirl.create(:type, :name => type_name)
  end

  project = Project.find_by_identifier(project_name)
  project.types = types
  project.save!
end

Then /^I should not see the "([^"]*)" type$/ do |name|
  page.all(:css, '.timelines-pet-name', :text => name).should be_empty
end
