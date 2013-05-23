FactoryGirl.define do
  factory :variable_cost_object do
    association :project, :factory => :project
    sequence(:subject) { |n| "Cost Object No. #{n}" }
    sequence(:description) { |n| "I am a Cost Object No. #{n}" }
    association :author, :factory => :user
    fixed_date Time.now
  end
end
