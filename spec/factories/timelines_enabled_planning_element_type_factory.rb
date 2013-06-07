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
  factory(:timelines_enabled_planning_element_type, :class => Timelines::EnabledPlanningElementType) do
    project               { |e| e.association(:project) }
    planning_element_type { |e| e.association(:timelines_planning_element_type) }
  end
end
