FactoryGirl.define do
  factory :version do
    sequence(:name) { |i| "Version #{i}" }
    effective_date Date.today + 14.days
    project
  end
end
