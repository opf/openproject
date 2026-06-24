# frozen_string_literal: true

FactoryBot.define do
  factory :work_package_help_text, class: "AttributeHelpText::WorkPackage" do
    type { "AttributeHelpText::WorkPackage" }
    help_text { "Attribute help text" }
    caption { "Some caption" }
    attribute_name { "status" }
  end

  factory :project_help_text, class: "AttributeHelpText::Project" do
    type { "AttributeHelpText::Project" }
    help_text { "Attribute help text" }
    caption { "Some caption" }
    attribute_name { "status" }
  end

  factory :user_help_text, class: "AttributeHelpText::User" do
    type { "AttributeHelpText::User" }
    help_text { "Attribute help text" }
    caption { "Some caption" }
    attribute_name { "custom_field_1" }
  end
end
