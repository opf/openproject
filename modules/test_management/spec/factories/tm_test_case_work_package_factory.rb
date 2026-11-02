# frozen_string_literal: true

FactoryBot.define do
  factory :tm_test_case_work_package, class: "TestManagement::TestCaseWorkPackage" do
    test_case factory: :tm_test_case
    work_package
  end
end
