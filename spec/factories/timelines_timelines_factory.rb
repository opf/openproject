FactoryGirl.define do
  factory(:timelines_timelines, :class => Timelines::Timeline) do
    sequence(:name) { |n| "Timeline No. #{n}" }
    association :project
  end
end
