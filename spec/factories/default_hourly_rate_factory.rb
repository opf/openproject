FactoryGirl.define do
  factory :default_hourly_rate do
    valid_from Date.today
    rate 50.0
  end
end
