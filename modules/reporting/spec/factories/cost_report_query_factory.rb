# frozen_string_literal: true

FactoryBot.define do
  factory :cost_report_query, class: "CostReportQuery" do
    sequence(:name) { |n| "Cost report query #{n}" }
    principal factory: :user
  end
end
