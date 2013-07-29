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

InstanceFinder.register(:type, Proc.new { |name| Type.find_by_name(name) })

RouteMap.register(Type, "/types")

Then /^I should not see the "([^"]*)" type$/ do |name|
  page.all(:css, '.timelines-pet-name', :text => name).should be_empty
end

Given /^the following types are default for projects of type "([^"]*)"$/ do |project_type_name, pe_type_names|
  project_type = ProjectType.find_by_name!(project_type_name)

  pe_type_names = pe_type_names.raw.flatten
  pe_type_names.each do |pe_type_name|
    FactoryGirl.create(:default_planning_element_type,
                       :project_type_id          => project_type.id,
                       :planning_element_type_id => Type.find_by_name!(pe_type_name).id)
  end
end
