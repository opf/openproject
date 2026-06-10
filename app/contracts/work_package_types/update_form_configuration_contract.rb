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
  class UpdateFormConfigurationContract < BaseContract
    include RequiresEnterpriseGuard

    self.enterprise_action = :edit_attribute_groups
    self.enterprise_condition = ->(*) { custom_groups_modified? }

    attribute :attribute_groups

    validate :validate_attribute_group_names
    validate :validate_attribute_groups

    private

    def validate_attribute_group_names
      return unless model.attribute_groups_changed?

      seen = Set.new
      model.attribute_groups.each do |group|
        errors.add(:attribute_groups, :group_without_name) if group.key.blank?

        group_name = visible_group_name(group)
        errors.add(:attribute_groups, :duplicate_group, group: group_name) if seen.add?(group_name).nil?
      end
    end

    def validate_attribute_groups
      return unless model.attribute_groups_changed?

      model.attribute_groups_objects.each do |group|
        if group.is_a?(Type::QueryGroup)
          validate_query_group(group)
        else
          validate_attribute_group(group)
        end
      end
    end

    def validate_query_group(group)
      query_call = rebuild_query_group(group)
      return add_invalid_query_error(group, query_call.errors) unless query_call.success?

      validate_rebuilt_query_group(group, query_call.result)
    end

    def validate_attribute_group(group)
      valid_attributes = model.work_package_attributes.keys

      group.attributes.each do |key|
        if key.is_a?(String) && valid_attributes.exclude?(key)
          errors.add(
            :attribute_groups,
            I18n.t("activerecord.errors.models.type.attributes.attribute_groups.attribute_unknown_name",
                   attribute: key)
          )
        end
      end
    end

    def custom_groups_modified?
      return false unless model.attribute_groups_changed?

      old_keys = normalized_old_keys
      new_keys = model.attribute_groups.map(&:key)

      (new_keys - old_keys - Type.default_groups.keys).any?
    end

    def normalized_old_keys
      seen_keys = model.attribute_groups_was.filter_map(&:first).compact_blank.map(&:to_s)

      model.attribute_groups_was.map do |group|
        key = group.first.presence&.to_s
        key || normalized_legacy_group_key(seen_keys).tap { |legacy_key| seen_keys << legacy_key }
      end
    end

    def normalized_legacy_group_key(seen_keys)
      Type::FormGroup.next_untitled_key(seen_keys)
    end

    def visible_group_name(group)
      group.translated_key.to_s.strip
    end

    def rebuild_query_group(group)
      ::WorkPackageTypes::FormConfiguration::EmbeddedQueryBuilder.rebuild(query: group.query, user:)
    end

    def validate_rebuilt_query_group(group, query)
      contract = Queries::CreateContract.new(query, user)
      return if contract.validate

      add_invalid_query_error(group, contract.errors)
    end

    def add_invalid_query_error(group, error_collection)
      errors.add(:attribute_groups, :query_invalid, group: group.key, details: error_collection.full_messages.to_sentence)
    end
  end
end
