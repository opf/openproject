FactoryGirl.define do
  factory :task do
    association :tracker, :factory => :tracker_task
    subject "Printing Recipes"
    description "Unable to print recipes"
    association :priority, :factory => :priority
    association :author, :factory => :user
  end
end
