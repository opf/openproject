# frozen_string_literal: true

FactoryBot.define do
  factory :tm_milestone, class: "TestManagement::Milestone" do
    project
    sequence(:name) { |n| "Milestone #{n}" }
    status { "open" }

    trait :started do
      status { "started" }
      started_at { Time.current }
    end

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
    end

    trait :overdue do
      due_date { Date.current - 3.days }
    end
  end

  factory :tm_milestone_work_package, class: "TestManagement::MilestoneWorkPackage" do
    milestone factory: :tm_milestone
    work_package { association :work_package, project: milestone.project }
  end
end
