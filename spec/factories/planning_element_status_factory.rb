FactoryGirl.define do
  factory(:planning_element_status, :class => PlanningElementStatus) do
    sequence(:name) { |n| "Planning Element Status No. #{n}" }

    sequence(:position) { |n| n }
  end
end
