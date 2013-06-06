FactoryGirl.define do
  factory(:timelines_enabled_planning_element_type, :class => Timelines::EnabledPlanningElementType) do
    project               { |e| e.association(:project) }
    planning_element_type { |e| e.association(:timelines_planning_element_type) }
  end
end
