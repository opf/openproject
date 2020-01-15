#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

FactoryBot.define do
  factory :custom_field do
    name { 'Custom Field' }
    regexp { '' }
    is_required { false }
    min_length { false }
    default_value { '' }
    max_length { false }
    editable { true }
    possible_values { '' }
    visible { true }
    field_format { 'bool' }

    callback(:after_create) do
      # As the request store keeps track of the created custom fields
      RequestStore.clear!
    end

    factory :project_custom_field, class: ProjectCustomField do
      sequence(:name) { |n| "Project custom field #{n}" }

      factory :list_project_custom_field do
        sequence(:name) { |n| "List project custom field #{n}" }
        field_format { 'list' }
        possible_values { ['A', 'B', 'C', 'D', 'E', 'F', 'G'] }
      end

      factory :version_project_custom_field do
        sequence(:name) { |n| "Version project custom field #{n}" }
        field_format { 'version' }
      end

      factory :bool_project_custom_field do
        sequence(:name) { |n| "Bool project custom field #{n}" }
        field_format { 'bool' }
      end

      factory :user_project_custom_field do
        sequence(:name) { |n| "User project custom field #{n}" }
        field_format { 'user' }
      end

      factory :int_project_custom_field do
        sequence(:name) { |n| "Int project custom field #{n}" }
        field_format { 'int' }
      end

      factory :float_project_custom_field do
        sequence(:name) { |n| "Float project custom field #{n}" }
        field_format { 'float' }
      end

      factory :text_project_custom_field do
        sequence(:name) { |n| "Text project custom field #{n}" }
        field_format { 'text' }
      end

      factory :string_project_custom_field do
        sequence(:name) { |n| "String project custom field #{n}" }
        field_format { 'string' }
      end

      factory :date_project_custom_field do
        sequence(:name) { |n| "Date project custom field #{n}" }
        field_format { 'date' }
      end
    end

    factory :user_custom_field, class: UserCustomField do
      sequence(:name) { |n| "User Custom Field #{n}" }
      type { 'UserCustomField' }

      factory :boolean_user_custom_field do
        name { 'BooleanUserCustomField' }
        field_format { 'bool' }
      end

      factory :integer_user_custom_field do
        name { 'IntegerUserCustomField' }
        field_format { 'int' }
      end

      factory :text_user_custom_field do
        name { 'TextUserCustomField' }
        field_format { 'text' }
      end

      factory :string_user_custom_field do
        name { 'StringUserCustomField' }
        field_format { 'string' }
      end

      factory :float_user_custom_field do
        name { 'FloatUserCustomField' }
        field_format { 'float' }
      end

      factory :list_user_custom_field do
        name { 'ListUserCustomField' }
        field_format { 'list' }
        possible_values { ['1', '2', '3', '4', '5', '6', '7'] }
      end

      factory :date_user_custom_field do
        name { 'DateUserCustomField' }
        field_format { 'date' }
      end
    end

    factory :wp_custom_field, class: WorkPackageCustomField do
      sequence(:name) { |n| "Work package custom field #{n}" }
      type { 'WorkPackageCustomField' }

      factory :list_wp_custom_field do
        sequence(:name) { |n| "List CF #{n}" }
        field_format { 'list' }
        possible_values { ['A', 'B', 'C', 'D', 'E', 'F', 'G'] }
      end

      factory :version_wp_custom_field do
        sequence(:name) { |n| "Version work package custom field #{n}" }
        field_format { 'version' }
      end

      factory :bool_wp_custom_field do
        sequence(:name) { |n| "Bool WP custom field #{n}" }
        field_format { 'bool' }
      end

      factory :user_wp_custom_field do
        sequence(:name) { |n| "User WP custom field #{n}" }
        field_format { 'user' }
      end

      factory :int_wp_custom_field do
        sequence(:name) { |n| "Int WP custom field #{n}" }
        field_format { 'int' }
      end

      factory :float_wp_custom_field do
        sequence(:name) { |n| "Float WP custom field #{n}" }
        field_format { 'float' }
      end

      factory :text_wp_custom_field do
        sequence(:name) { |n| "Text WP custom field #{n}" }
        field_format { 'text' }
      end

      factory :string_wp_custom_field do
        sequence(:name) { |n| "String WP custom field #{n}" }
        field_format { 'string' }
      end

      factory :date_wp_custom_field do
        sequence(:name) { |n| "Date WP custom field #{n}" }
        field_format { 'date' }
      end
    end

    factory :issue_custom_field, class: WorkPackageCustomField do
      sequence(:name) { |n| "Issue Custom Field #{n}" }

      factory :user_issue_custom_field do
        field_format { 'user' }
        sequence(:name) { |n| "UserWorkPackageCustomField #{n}" }
      end

      factory :text_issue_custom_field do
        field_format { 'text' }
        sequence(:name) { |n| "TextWorkPackageCustomField #{n}" }
      end

      factory :integer_issue_custom_field do
        field_format { 'int' }
        sequence(:name) { |n| "IntegerWorkPackageCustomField #{n}" }
      end
    end

    factory :time_entry_custom_field, class: TimeEntryCustomField do
      field_format { 'text' }
      sequence(:name) { |n| "TimeEntryCustomField #{n}" }
    end

    factory :version_custom_field, class: VersionCustomField do
      field_format { 'text' }
      sequence(:name) { |n| "Version Custom Field #{n}" }

      factory :int_version_custom_field do
        sequence(:name) { |n| "Int version custom field #{n}" }
        field_format { 'int' }
      end

      factory :list_version_custom_field do
        sequence(:name) { |n| "List version custom field #{n}" }
        field_format { 'list' }
        possible_values { ['A', 'B', 'C', 'D', 'E', 'F', 'G'] }
      end
    end
  end
end
