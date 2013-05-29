FactoryGirl.define do
  factory(:planning_element_type, :class => PlanningElementType) do
    sequence(:name) { |n| "Planning Element Type No. #{n}" }

    in_aggregation true
    is_milestone false
    is_default false

    sequence(:position) { |n| n }
  end
end

FactoryGirl.define do
  factory(:planning_element_type_milestone,
          :parent => :planning_element_type) do
    is_milestone true
  end
end
