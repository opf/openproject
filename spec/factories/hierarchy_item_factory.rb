# frozen_string_literal: true

FactoryBot.define do
  factory :hierarchy_item, class: "CustomField::Hierarchy::Item" do
    sequence(:label) { |n| "Item #{n}" }
  end
end
