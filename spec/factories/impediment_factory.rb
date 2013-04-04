FactoryGirl.define do
  factory :impediment do
    association :tracker, :factory => :tracker_task
    subject "Impeding progress"
    description "Unable to print recipes"
    association :priority, :factory => :priority
    association :author, :factory => :user
  end
end
