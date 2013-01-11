FactoryGirl.define do
  factory :attachment do
    container :factory => :document
    author :factory => :user
    sequence(:filename) { |n| "test#{n}.test" }
    sequence(:disk_filename) { |n| "test#{n}.test" }
  end
end
