# frozen_string_literal: true

FactoryBot.define do
  factory :tm_test_plan, class: "TestManagement::TestPlan" do
    project
    sequence(:name) { |n| "Test plan #{n}" }
    state { "active" }
    author factory: :user

    trait :completed do
      state { "completed" }
      finished_at { Time.current }
    end
  end

  factory :tm_test_plan_entry, class: "TestManagement::TestPlanEntry" do
    test_plan factory: :tm_test_plan
    sequence(:name) { |n| "Plan entry #{n}" }
    selection_mode { "all" }
    position { 0 }
  end

  factory :tm_test_plan_work_package, class: "TestManagement::TestPlanWorkPackage" do
    test_plan factory: :tm_test_plan
    work_package { association :work_package, project: test_plan.project }
  end
end
