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

When /^I follow the edit link of the project type "([^"]*)"$/ do |project_type_name|
  type = ProjectType.find_by_name(project_type_name)

  href = Rails.application.routes.url_helpers.edit_project_type_path(type)

  click_link(type.name, :href => href)
end
