FactoryGirl.define do
  factory(:project_type, :class => ProjectType) do
    sequence(:name) { |n| "Project Type No. #{n}" }
    allows_association true
    sequence(:position) { |n| n }
  end
end
