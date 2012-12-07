FactoryGirl.define do
  factory :attachment do
    container :factory => :document
    sequence(:filename) { |n| "test#{n}.test" }
    sequence(:disk_filename) { |n| "test#{n}.test" }
  end
end
