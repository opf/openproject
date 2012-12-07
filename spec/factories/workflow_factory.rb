FactoryGirl.define do
  factory :workflow do
    old_status :factory => :issue_status
    new_status :factory => :issue_status
    role

    factory :workflow_with_default_status do
      old_status :factory => :default_issue_status
    end
  end
end
