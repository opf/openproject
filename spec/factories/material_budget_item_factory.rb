FactoryGirl.define do
  factory :material_budget_item do
    association :cost_type, :factory => :cost_type
    association :cost_object, :factory => :variable_cost_object
    units 0.0
  end
end
