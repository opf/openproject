FactoryGirl.define do
  factory(:available_project_status, :class => AvailableProjectStatus) do |d|
    reported_project_status { |e| e.association :reported_project_status }
    project_type            { |e| e.association :project_type }
  end
end
