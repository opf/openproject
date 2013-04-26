FactoryGirl.define do
  factory :cost_entry  do
    association :cost_type, :factory => :cost_type
  end
end
