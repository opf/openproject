FactoryGirl.define do
  factory :time_entry_activity do
    sequence(:name) { |n| "Time Entry Activity No. #{n}" }
  end
end


