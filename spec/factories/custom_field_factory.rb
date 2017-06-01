#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory :custom_field do
    name 'Custom Field'
    regexp ''
    is_required false
    min_length false
    default_value ''
    max_length false
    editable true
    possible_values ''
    visible true
    field_format 'bool'

    factory :user_custom_field, class: UserCustomField do
      sequence(:name) do |n| "User Custom Field #{n}" end
      type 'UserCustomField'

      factory :boolean_user_custom_field do
        name 'BooleanUserCustomField'
        field_format 'bool'
      end

      factory :integer_user_custom_field do
        name 'IntegerUserCustomField'
        field_format 'int'
      end

      factory :text_user_custom_field do
        name 'TextUserCustomField'
        field_format 'text'
      end

      factory :string_user_custom_field do
        name 'StringUserCustomField'
        field_format 'string'
      end

      factory :float_user_custom_field do
        name 'FloatUserCustomField'
        field_format 'float'
      end

      factory :list_user_custom_field do
        name 'ListUserCustomField'
        field_format 'list'
        possible_values ['1', '2', '3', '4', '5', '6', '7']
      end

      factory :date_user_custom_field do
        name 'DateUserCustomField'
        field_format 'date'
      end
    end

    factory :wp_custom_field, class: WorkPackageCustomField do
      sequence(:name) do |n| "Work package custom field #{n}" end
      type 'WorkPackageCustomField'

      factory :list_wp_custom_field do
        sequence(:name) do |n| "List CF #{n}" end
        field_format 'list'
        possible_values ['A', 'B', 'C', 'D', 'E', 'F', 'G']
      end

      factory :version_wp_custom_field do
        sequence(:name) do |n| "Version work package custom field #{n}" end
        field_format 'version'
      end

      factory :bool_wp_custom_field do
        sequence(:name) do |n| "Bool WP custom field #{n}" end
        field_format 'bool'
      end

      factory :user_wp_custom_field do
        sequence(:name) do |n| "User WP custom field #{n}" end
        field_format 'user'
      end

      factory :int_wp_custom_field do
        sequence(:name) do |n| "Int WP custom field #{n}" end
        field_format 'int'
      end

      factory :float_wp_custom_field do
        sequence(:name) do |n| "Float WP custom field #{n}" end
        field_format 'float'
      end

      factory :text_wp_custom_field do
        sequence(:name) do |n| "Text WP custom field #{n}" end
        field_format 'text'
      end

      factory :string_wp_custom_field do
        sequence(:name) do |n| "String WP custom field #{n}" end
        field_format 'string'
      end

      factory :date_wp_custom_field do
        sequence(:name) do |n| "Date WP custom field #{n}" end
        field_format 'date'
      end
    end

    factory :issue_custom_field, class: WorkPackageCustomField do
      sequence(:name) do |n| "Issue Custom Field #{n}" end

      factory :user_issue_custom_field do
        field_format 'user'
        sequence(:name) { |n| "UserWorkPackageCustomField #{n}" }
      end

      factory :text_issue_custom_field do
        field_format 'text'
        sequence(:name) { |n| "TextWorkPackageCustomField #{n}" }
      end

      factory :integer_issue_custom_field do
        field_format 'int'
        sequence(:name) { |n| "IntegerWorkPackageCustomField #{n}" }
      end
    end

    factory :time_entry_custom_field, class: TimeEntryCustomField do
      field_format 'text'
      sequence(:name) { |n| "TimeEntryCustomField #{n}" }
    end
  end
end
