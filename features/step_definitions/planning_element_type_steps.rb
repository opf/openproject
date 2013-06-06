# change from symbol to constant once namespace is removed

InstanceFinder.register(:timelines_planning_element_type, Proc.new { |name| Timelines::PlanningElementType.find_by_name(name) })

RouteMap.register(Timelines::PlanningElementType, "/timelines/planning_element_types")
