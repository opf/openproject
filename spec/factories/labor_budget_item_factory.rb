FactoryGirl.define do
  factory :labor_budget_item do
    association :user, :factory => :user
    association :cost_object, :factory => :variable_cost_object
    hours 0.0
  end
end
