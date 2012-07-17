Factory.define :labor_budget_item do |i|
  i.association :user, :factory => :user
  i.association :cost_object, :factory => :variable_cost_object
  i.hours 0.0
end
