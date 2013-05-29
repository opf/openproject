FactoryGirl.define do
  factory(:alternate_date, :class => AlternateDate) do
    sequence(:start_date) { |n| ((n - 1) * 7).days.since.to_date }
    sequence(:end_date)   { |n| (n * 7).days.since.to_date }

    planning_element { |e| e.association(:planning_element) }
  end
end

FactoryGirl.define do
  factory(:alternate_scenaric_date, :parent => :alternate_date) do |d|
    scenario { |e| e.association(:scenario) }
  end
end

FactoryGirl.define do
  factory(:alternate_historic_date, :parent => :alternate_date) do |d|
    scenario nil

    sequence(:created_at) { |n| n.weeks.ago.to_date }
    sequence(:updated_at) { |n| n.weeks.ago.to_date }
  end
end
