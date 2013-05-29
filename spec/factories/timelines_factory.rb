FactoryGirl.define do
  factory(:timelines, :class => Timeline) do
    sequence(:name) { |n| "Timeline No. #{n}" }
    association :project
  end
end
