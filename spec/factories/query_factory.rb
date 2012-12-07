FactoryGirl.define do
  factory :query do
    project
    user :factory => :user
    sequence(:name) { |n| "Query {n}" }

    factory :public_query do
      is_public true
      sequence(:name) { |n| "Public query {n}" }
    end

    factory :private_query do
      is_public false
      sequence(:name) { |n| "Private query {n}" }
    end
  end
end
