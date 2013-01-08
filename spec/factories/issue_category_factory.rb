FactoryGirl.define do
  factory :issue_category do
    sequence(:name) { |n| "Issue category #{n}" }
    project

    after :build do |issue|
      issue.assigned_to = issue.project.users.first unless issue.assigned_to
    end
  end
end

