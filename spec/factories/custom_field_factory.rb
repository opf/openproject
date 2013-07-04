#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
      type "UserCustomField"

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
      type "WorkPackageCustomField"

      factory :user_issue_custom_field do
        field_format "user"
        sequence(:name) { |n| "UserWorkPackageCustomField #{n}" }
      end
    end
  end
end
