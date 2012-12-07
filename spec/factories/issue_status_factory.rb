FactoryGirl.define do
  factory :issue_status do
    sequence(:name) { |n| "status #{n}" }
    is_closed false

    factory :default_issue_status do
      is_default true
    end
  end
end

