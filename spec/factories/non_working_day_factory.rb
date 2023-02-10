FactoryBot.define do
  factory :non_working_day do
    sequence(:name) { |n| "Non working on #{Date.current + n.day} " }
    sequence(:date) { |n| Date.current + n.day }
  end
end
