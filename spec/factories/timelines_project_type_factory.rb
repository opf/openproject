FactoryGirl.define do
  factory(:timelines_project_type, :class => Timelines::ProjectType) do
    sequence(:name) { |n| "Project Type No. #{n}" }
    allows_association true
    sequence(:position) { |n| n }
  end
end
