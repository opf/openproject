FactoryGirl.define do
  factory :time_entry do
    project
    user
    issue
    spent_on Date.today
  end
end

