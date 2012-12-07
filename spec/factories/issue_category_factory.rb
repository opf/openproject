FactoryGirl.define do
  factory :issue_category do
    project
    assigned_to :factory => :user
    sequence(:name) { |n| "Issue category #{n}" }
  end
end

