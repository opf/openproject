FactoryGirl.define do
  factory :changeset do
    sequence(:revision) { |n| "#{n}" }
    committed_on Time.now
    commit_date Date.today
  end
end

