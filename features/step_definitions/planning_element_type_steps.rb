# change from symbol to constant once namespace is removed

InstanceFinder.register(:planning_element_type, Proc.new { |name| PlanningElementType.find_by_name(name) })

RouteMap.register(PlanningElementType, "/timelines/planning_element_types")
