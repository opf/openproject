FactoryGirl.define do
  factory :news do
    sequence(:title) { |n| "News title#{n}" }
    sequence(:summary) { |n| "News summary#{n}" }
    sequence(:description) { |n| "News description#{n}" }
    author :factory => :user
    project
  end
end
