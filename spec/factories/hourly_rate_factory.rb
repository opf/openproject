FactoryGirl.define do
  factory :hourly_rate do
    valid_from Date.today
    rate 50.0
  end
end
