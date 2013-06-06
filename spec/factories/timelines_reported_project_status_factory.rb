FactoryGirl.define do
  factory(:timelines_reported_project_status, :class => Timelines::ReportedProjectStatus) do
    sequence(:name)     { |n| "Reported Project Status No. #{n}" }
    sequence(:position) { |n| n }
  end
end
