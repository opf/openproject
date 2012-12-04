FactoryGirl.define do
  factory :document_category do
    project
    sequence(:name) { |n| "I am Category No. #{n}" }
  end
end
