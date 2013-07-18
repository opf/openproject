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

Given /^there is a project named "([^"]*)"(?: of type "([^"]*)")?$/ do |name, project_type_name|
  attributes = { :name => name,
                 :identifier => name.downcase.gsub(" ", "_")}

  if project_type_name
    attributes.merge!(:project_type => ProjectType.find_by_name!(project_type_name))
  end

  FactoryGirl.create(:project, attributes)
end
