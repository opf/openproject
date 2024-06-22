FactoryBot.define do
  factory :work_package_help_text, class: "AttributeHelpText::WorkPackage" do
    type { "AttributeHelpText::WorkPackage" }
    help_text { "Attribute help text" }
    attribute_name { "status" }
  end

  factory :project_help_text, class: "AttributeHelpText::Project" do
    type { "AttributeHelpText::Project" }
    help_text { "Attribute help text" }
    attribute_name { "status" }
  end
end
