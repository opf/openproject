# frozen_string_literal: true

FactoryBot.define do
  factory :tm_configuration_group, class: "TestManagement::ConfigurationGroup" do
    project
    sequence(:name) { |n| "Config group #{n}" }
  end

  factory :tm_configuration, class: "TestManagement::Configuration" do
    configuration_group factory: :tm_configuration_group
    sequence(:name) { |n| "Config #{n}" }
  end
end
