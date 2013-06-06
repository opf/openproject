FactoryGirl.define do
  factory(:timelines_planning_element_status, :class => Timelines::PlanningElementStatus) do
    sequence(:name) { |n| "Planning Element Status No. #{n}" }

    sequence(:position) { |n| n }
  end
end
