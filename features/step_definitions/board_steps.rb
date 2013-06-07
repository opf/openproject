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

Given(/^there is a board "(.*?)" for project "(.*?)"$/) do |board_name, project_identifier|
  FactoryGirl.create :board, :project => get_project(project_identifier), :name => board_name
end
