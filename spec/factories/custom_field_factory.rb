FactoryGirl.define do
  factory :custom_field do
    name "Custom Field"
    regexp ""
    is_required false
    min_length false
    default_value ""
    max_length false
    editable true
    possible_values ""
    visible true
    field_format "bool"

    factory :user_custom_field do
      sequence(:name) { |n| "User Custom Field #{n}" }

      factory :boolean_user_custom_field do
        name "BooleanUserCustomField"
        field_format "bool"
      end

      factory :integer_user_custom_field do
        name "IntegerUserCustomField"
        field_format "int"
      end

      factory :text_user_custom_field do
        name "TextUserCustomField"
        field_format "text"
      end

      factory :string_user_custom_field do
        name "StringUserCustomField"
        field_format "string"
      end

      factory :float_user_custom_field do
        name "FloatUserCustomField"
        field_format "float"
      end

      factory :list_user_custom_field do
        name "ListUserCustomField"
        field_format "list"
        possible_values ["1", "2", "3", "4", "5", "6", "7"]
      end

      factory :date_user_custom_field do
        name "DateUserCustomField"
        field_format "date"
      end
    end

    factory :issue_custom_field do
      sequence(:name) { |n| "Issue Custom Field #{n}" }

      factory :user_issue_custom_field do
        field_format "user"
        sequence(:name) { |n| "UserIssueCustomField #{n}" }
      end
    end
  end
end
