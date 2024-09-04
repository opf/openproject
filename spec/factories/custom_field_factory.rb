#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :custom_field do
    transient do
      # These values are used internally to customize the  custom field name
      # when using traits. They are not meant to be set externally.
      _format_name do
        [
          multi_value ? "multi-" : nil,
          field_format
        ].compact.join
      end
      _type_name { instance.class.name.underscore.humanize(capitalize: false) }
    end
    sequence(:name) do |n, _e|
      [_format_name, _type_name, n.to_s].join(" ").capitalize
    end
    regexp { "" }
    is_required { false }
    min_length { false }
    default_value { "" }
    max_length { false }
    editable { true }
    possible_values { "" }
    admin_only { false }
    field_format { "bool" }

    after(:create) do
      # As the request store keeps track of the created custom fields
      RequestStore.clear!
    end

    trait :boolean do
      _format_name { "boolean" }
      field_format { "bool" }
    end

    trait :string do
      field_format { "string" }
    end

    trait :text do
      field_format { "text" }
    end

    trait :integer do
      _format_name { "integer" }
      field_format { "int" }
    end

    trait :float do
      field_format { "float" }
    end

    trait :date do
      field_format { "date" }
    end

    trait :list do
      transient do
        default_option { nil }
        default_options { nil }
      end
      field_format { "list" }
      multi_value { false }
      possible_values { ["A", "B", "C", "D", "E", "F", "G"] }

      # update custom options default value from the default_option transient
      # field for non-multiselect field
      after(:create) do |custom_field, evaluator|
        default_option = evaluator.default_option
        next if default_option.blank?

        # ensure the right options are used
        if evaluator.multi_value
          raise "Please use default_options instead of default_option for multi_value list field."
        end

        if default_option.is_a?(Array)
          raise "default_option #{default_option.inspect} is an array but the list custom field is not a multi_value." \
                "Please use a single value instead."
        end

        default_custom_option = custom_field.possible_values.find_by(value: default_option)
        if default_custom_option.nil?
          raise "Default option #{default_option.inspect} not found. " \
                "Possible options are #{custom_field.possible_values.pluck(:value).inspect}"
        end

        default_custom_option.update!(default_value: true)
      end

      # update custom options default value from the default_options transient
      # field for multiselect field
      after(:create) do |custom_field, evaluator|
        default_options = Array(evaluator.default_options)
        next if default_options.blank?

        default_custom_options = custom_field.possible_values.where(value: default_options)
        if default_custom_options.size != default_options.size
          not_found_options = default_options - default_custom_options.pluck(:value)
          raise "Default options #{not_found_options.inspect} not found. " \
                "Possible options are #{custom_field.possible_values.pluck(:value).inspect}"
        end

        default_custom_options.update_all(default_value: true)
      end
    end

    trait :multi_list do
      list
      multi_value { true }
    end

    trait :version do
      field_format { "version" }
    end

    trait :multi_version do
      field_format { "version" }
      multi_value { true }
    end

    trait :user do
      field_format { "user" }
    end

    trait :multi_user do
      field_format { "user" }
      multi_value { true }
    end

    trait :link do
      field_format { "link" }
    end

    factory :project_custom_field, class: "ProjectCustomField" do
      project_custom_field_section

      transient do
        projects { [] }
      end

      # enable the the custom_field for the given projects
      after(:create) do |custom_field, evaluator|
        projects = Array(evaluator.projects)
        next if projects.blank?

        projects.each do |project|
          unless project.project_custom_fields.include?(custom_field)
            create(:project_custom_field_project_mapping, project:, project_custom_field: custom_field)
          end
        end
      end

      factory :boolean_project_custom_field, traits: [:boolean]
      factory :string_project_custom_field, traits: [:string]
      factory :text_project_custom_field, traits: [:text]
      factory :integer_project_custom_field, traits: [:integer]
      factory :float_project_custom_field, traits: [:float]
      factory :date_project_custom_field, traits: [:date]
      factory :list_project_custom_field, traits: [:list]
      factory :version_project_custom_field, traits: [:version]
      factory :user_project_custom_field, traits: [:user]
      factory :link_project_custom_field, traits: [:link]
    end

    factory :user_custom_field, class: "UserCustomField"

    factory :group_custom_field, class: "GroupCustomField"

    factory :wp_custom_field, class: "WorkPackageCustomField" do
      _type_name { "WP custom field" }
      is_filter { true }

      transient do
        projects { [] }
      end

      after(:create) do |custom_field, evaluator|
        evaluator.projects.each do |project|
          project.work_package_custom_fields << custom_field
        end
      end

      factory :boolean_wp_custom_field, traits: [:boolean]
      factory :string_wp_custom_field, traits: [:string]
      factory :text_wp_custom_field, traits: [:text]
      factory :integer_wp_custom_field, traits: [:integer]
      factory :float_wp_custom_field, traits: [:float]
      factory :date_wp_custom_field, traits: [:date]
      factory :list_wp_custom_field, traits: [:list]
      factory :multi_list_wp_custom_field, traits: [:multi_list]
      factory :version_wp_custom_field, traits: [:version]
      factory :multi_version_wp_custom_field, traits: [:multi_version]
      factory :user_wp_custom_field, traits: [:user]
      factory :multi_user_wp_custom_field, traits: [:multi_user]
      factory :link_wp_custom_field, traits: [:link]
    end

    factory :issue_custom_field, class: "WorkPackageCustomField" do
      _type_name { "issue custom field" }
    end

    factory :time_entry_custom_field, class: "TimeEntryCustomField" do
      field_format { "text" }
    end

    factory :version_custom_field, class: "VersionCustomField" do
      field_format { "text" }
    end
  end
end
