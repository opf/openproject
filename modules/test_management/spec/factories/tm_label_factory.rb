# frozen_string_literal: true

FactoryBot.define do
  factory :tm_label, class: "TestManagement::Label" do
    project
    sequence(:name) { |n| "label-#{n}" }
  end

  factory :tm_test_case_label, class: "TestManagement::TestCaseLabel" do
    test_case factory: :tm_test_case
    label { association :tm_label, project: test_case.project }
  end
end
