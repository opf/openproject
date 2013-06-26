FactoryGirl.define do
  factory :principal_role do |pr|
    pr.association :role, :factory => :global_role
    pr.association :principal, :factory => :user
  end
end
