FactoryGirl.define do
  factory(:timelines_reporting, :class => Timelines::Reporting) do
    project { |e| e.association(:project) }
    reporting_to_project { |e| e.association(:project) }
  end
end
