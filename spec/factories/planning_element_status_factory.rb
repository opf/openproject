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
  factory(:planning_element_status, :class => PlanningElementStatus) do
    sequence(:name) { |n| "Planning Element Status No. #{n}" }

    sequence(:position) { |n| n }
  end
end
