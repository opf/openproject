FactoryGirl.define do
  factory :time_entry do
    project
    user
    issue
    spent_on Date.today
    activity :factory => :time_entry_activity
  end
end

