FactoryGirl.define do
  factory :sprint do
    name "version"
    effective_date Date.today + 14.days
    sharing "none"
    status "open"
  end
end

