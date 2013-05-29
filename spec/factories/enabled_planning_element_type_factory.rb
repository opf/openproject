FactoryGirl.define do
  factory(:enabled_planning_element_type, :class => EnabledPlanningElementType) do
    project               { |e| e.association(:project) }
    planning_element_type { |e| e.association(:planning_element_type) }
  end
end
