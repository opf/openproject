# frozen_string_literal: true

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

module WorkPackageTypes
  module FormConfiguration
    module Concern
      extend ActiveSupport::Concern

      def initialize(user:, type:, **)
        super()
        @user = user
        @type = type
      end

      private

      attr_reader :type,
                  :user

      def active_groups
        type.attribute_groups.reject { |group| group.key.to_s == "__empty" }
      end

      def find_group(group_key)
        active_groups.find { |group| group_identifier_match?(group, group_key) }
      end

      def find_attribute_group(group_key)
        type.attribute_groups.find do |group|
          group.group_type == :attribute && group_identifier_match?(group, group_key)
        end
      end

      def find_row(row_key)
        active_groups
          .select { |group| group.group_type == :attribute }
          .each do |group|
            index = group.attributes.index { |attribute| attribute_identifier_match?(attribute, row_key) }
            return { group:, index: } if index
          end

        nil
      end

      def group_identifier_match?(group, identifier)
        expected = identifier.to_s.strip

        [
          group.key,
          group.display_name,
          group.translated_key
        ].compact.map { |value| value.to_s.strip }.include?(expected)
      end

      def attribute_identifier_match?(attribute, identifier)
        attribute.to_s.strip == identifier.to_s.strip
      end

      def persist_groups(groups)
        assign_groups(groups)
        return contract_failure unless form_configuration_contract.validate

        persist_type
      end

      def failure_with_message(message)
        type.errors.clear
        type.errors.add(:base, message)

        ServiceResult.failure(result: type, errors: type.errors)
      end

      def build_query(query_props, name:)
        ::WorkPackageTypes::FormConfiguration::EmbeddedQueryBuilder.build(query_props:, name:, user:)
      end

      def normalized_groups(groups)
        groups = groups
                 .reject { |group| group.key.to_s == "__empty" }
        seen_keys = groups.filter_map(&:key).compact_blank.map(&:to_s)
        groups = groups.map { |group| normalize_group(group, seen_keys:) }
        prune_unavailable_attribute_group_items(groups)

        if groups.empty?
          [::Type::AttributeGroup.new(type, :__empty, [])]
        else
          groups
        end
      end

      def normalize_group(group, seen_keys:)
        return group if group.key.present?

        group.key = next_untitled_group_name(seen_keys)
        group
      end

      def next_untitled_group_name(seen_keys)
        Type::FormGroup.next_untitled_key(seen_keys).tap { |key| seen_keys << key }
      end

      def sync_active_custom_fields!
        type.custom_field_ids = active_groups
                                .select { |group| group.group_type == :attribute }
                                .flat_map(&:members)
                                .filter_map do |attribute|
                                  next unless CustomField.custom_field_attribute?(attribute)

                                  attribute.delete_prefix("custom_field_").to_i
                                end
                                .uniq
      end

      def prune_unavailable_attribute_group_items(groups)
        groups.each do |group|
          group.attributes = group.members if group.group_type == :attribute
        end
      end

      def assign_groups(groups)
        type.attribute_groups_will_change!
        type.attribute_groups_objects = normalized_groups(groups)
        sync_active_custom_fields!
      end

      def form_configuration_contract
        @form_configuration_contract ||= ::WorkPackageTypes::UpdateFormConfigurationContract.new(type, user, options: {})
      end

      def contract_failure
        ServiceResult.failure(result: type, errors: form_configuration_contract.errors)
      end

      def persist_type
        if type.save
          ServiceResult.success(result: type)
        else
          ServiceResult.failure(result: type, errors: type.errors)
        end
      end
    end
  end
end
