Factory.define :variable_cost_object do |m|
  m.association :project, :factory => :project
  m.sequence(:subject) { |n| "Cost Object No. #{n}" }
  m.sequence(:description) { |n| "I am a Cost Object No. #{n}" }
  m.fixed_date Time.now
end
