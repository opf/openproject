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

FactoryGirl.define do
  factory(:project_type, :class => ProjectType) do
    sequence(:name) { |n| "Project Type No. #{n}" }
    allows_association true
    sequence(:position) { |n| n }
  end
end
