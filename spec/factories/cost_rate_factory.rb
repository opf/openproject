FactoryGirl.define do
  factory :cost_rate do
    association :cost_type, :factory => :cost_type
    valid_from Date.today
    rate 50.0
  end
end
