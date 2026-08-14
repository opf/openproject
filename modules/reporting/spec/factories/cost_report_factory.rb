# frozen_string_literal: true

FactoryBot.define do
  factory :cost_report, class: "CostReport" do
    sequence(:name) { |n| "Cost report #{n}" }
    principal factory: :user
    public { false }
    query factory: :cost_report_query
  end
end
