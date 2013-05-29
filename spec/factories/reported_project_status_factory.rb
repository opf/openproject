FactoryGirl.define do
  factory(:reported_project_status, :class => ReportedProjectStatus) do
    sequence(:name)     { |n| "Reported Project Status No. #{n}" }
    sequence(:position) { |n| n }
  end
end
