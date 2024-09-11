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

require "model_contract"

module Types
  class BaseContract < ::ModelContract
    def self.model
      Type
    end

    attribute :name
    attribute :is_in_roadmap
    attribute :is_milestone
    attribute :is_default
    attribute :color_id
    attribute :project_ids
    attribute :description
    attribute :attribute_groups

    validate :validate_current_user_is_admin
    validate :validate_attribute_group_names
    validate :validate_attribute_groups

    def validate_current_user_is_admin
      unless user.admin?
        errors.add(:base, :error_unauthorized)
      end
    end

    def validate_attribute_group_names
      return unless model.attribute_groups_changed?

      seen = Set.new
      model.attribute_groups.each do |group|
        errors.add(:attribute_groups, :group_without_name) unless group.key.present?
        errors.add(:attribute_groups, :duplicate_group, group: group.key) if seen.add?(group.key).nil?
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
      query = group.query

      contract_class = query.persisted? ? Queries::UpdateContract : Queries::CreateContract
      contract = contract_class.new(query, user)

      unless contract.validate
        errors.add(:attribute_groups, :query_invalid, group: group.key, details: contract.errors.full_messages.join)
      end
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
  end
end
