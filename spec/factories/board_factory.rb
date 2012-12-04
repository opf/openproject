FactoryGirl.define do
  factory :board do
    project
    sequence(:name) { |n| "Board No. #{n}" }
    sequence(:description) { |n| "I am the Board No. #{n}" }
  end
end

