FactoryGirl.define do
  factory(:timelines_available_project_status, :class => Timelines::AvailableProjectStatus) do |d|
    reported_project_status { |e| e.association :timelines_reported_project_status }
    project_type            { |e| e.association :timelines_project_type }
  end
end
