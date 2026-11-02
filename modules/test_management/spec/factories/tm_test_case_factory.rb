# frozen_string_literal: true

FactoryBot.define do
  factory :tm_test_case, class: "TestManagement::TestCase" do
    project
    sequence(:title) { |n| "Test case #{n}" }
    status { "ready" }
    priority { "medium" }
    automated { false }
    author factory: :user

    trait :with_steps do
      after(:create) do |test_case|
        create(:tm_test_step, test_case:, position: 0)
        create(:tm_test_step, test_case:, position: 1)
      end
    end
  end
end
