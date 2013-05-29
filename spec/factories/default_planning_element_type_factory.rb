FactoryGirl.define do
  factory(:default_planning_element_type, :class => DefaultPlanningElementType) do
    project_type          { |e| e.association(:project_type) }
    planning_element_type { |e| e.association(:planning_element_type) }
  end
end
