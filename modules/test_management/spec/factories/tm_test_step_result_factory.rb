# frozen_string_literal: true

FactoryBot.define do
  factory :tm_test_step_result, class: "TestManagement::TestStepResult" do
    result factory: :tm_test_result
    kind { "case" }
    sequence(:position) { |n| n - 1 }
    status { "passed" }
    details { {} }
  end
end
