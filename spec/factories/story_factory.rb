FactoryGirl.define do
  factory :story do
    association :priority, :factory => :priority
    sequence(:subject) { |n| "story#{n}" }
    description "story story story"
    association :tracker, :factory => :tracker_feature
    association :author, :factory => :user
  end
end
