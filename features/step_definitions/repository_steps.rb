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

Given(/^the project "(.*?)" has a repository$/) do |project_name|

  project = Project.find(project_name)

  repo = FactoryGirl.build(:repository,
                           :project => project)

  Setting.enabled_scm = Setting.enabled_scm << repo.scm_name

  repo.save!
end


