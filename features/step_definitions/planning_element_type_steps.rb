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

InstanceFinder.register(PlanningElementType, Proc.new { |name| PlanningElementType.find_by_name(name) })

RouteMap.register(PlanningElementType, "/planning_element_types")
