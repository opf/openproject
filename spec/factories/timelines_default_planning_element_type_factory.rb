FactoryGirl.define do
  factory(:timelines_default_planning_element_type, :class => Timelines::DefaultPlanningElementType) do
    project_type          { |e| e.association(:timelines_project_type) }
    planning_element_type { |e| e.association(:timelines_planning_element_type) }
  end
end
