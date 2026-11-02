# frozen_string_literal: true

FactoryBot.define do
  factory :tm_test_step, class: "TestManagement::TestStep" do
    test_case factory: %i[tm_test_case]
    sequence(:position) { |n| n }
    action { "Do something" }
    expected_result { "Something happens" }
  end
end
