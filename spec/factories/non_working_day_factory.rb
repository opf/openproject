FactoryBot.define do
  factory :non_working_day do
    name { "MyString" }
    sequence(:date) { |n| Time.zone.today + n.day }
  end
end
