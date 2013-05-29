FactoryGirl.define do
  factory(:reporting, :class => Reporting) do
    project { |e| e.association(:project) }
    reporting_to_project { |e| e.association(:project) }
  end
end
