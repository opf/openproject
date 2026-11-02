# frozen_string_literal: true

FactoryBot.define do
  factory :tm_suite, class: "TestManagement::Suite" do
    project
    sequence(:name) { |n| "Suite #{n}" }
    position { 0 }
  end
end
