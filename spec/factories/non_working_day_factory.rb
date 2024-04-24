FactoryBot.define do
  factory :non_working_day do
    sequence(:name) { "Non working on #{date} " }
    sequence(:date) { |n| Date.current + n.day }
  end
end
