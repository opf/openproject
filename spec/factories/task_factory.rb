FactoryGirl.define do
  factory :task do
    association :type, :factory => :type_task
    subject "Printing Recipes"
    description "Just printing recipes"
    association :priority, :factory => :priority
    association :author, :factory => :user
  end
end
