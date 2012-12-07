FactoryGirl.define do
  factory :role do
    permissions []
    sequence(:name) { |n| "role_#{n}"}
    assignable true

    factory :non_member do
      name "Non member"
      builtin Role::BUILTIN_NON_MEMBER
      assignable false
    end

    factory :anonymous_role do
      name "Anonymous"
      builtin Role::BUILTIN_ANONYMOUS
      assignable false
    end
  end
end

