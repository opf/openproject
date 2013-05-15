FactoryGirl.define do
  factory :cost_query do
    association :user, :factory => :user
    association :project, :factory => :project
    sequence(:name) { |n| "Cost Query #{n}" }
    factory :private_cost_query do
      is_public false
    end
    factory :public_cost_query do
      is_public true
    end
  end
end
