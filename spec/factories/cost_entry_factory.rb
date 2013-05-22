FactoryGirl.define do
  factory :cost_entry  do
    project
    user { FactoryGirl.create(:user, :member_in_project => project)}
    issue { FactoryGirl.create(:issue, :project => project) }
    cost_type
    spent_on Date.today
    units 1
    comments ''
  end
end
