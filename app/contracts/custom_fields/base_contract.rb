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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  class BaseContract < ::ModelContract
    include RequiresAdminGuard

    attribute :admin_only
    stored_attribute :allow_additional_project_values, store: :settings do
      validate_project_admin_flag_enterprise(:allow_additional_project_values)
    end
    stored_attribute :allow_non_open_versions, store: :settings
    stored_attribute :content_right_to_left, store: :settings
    attribute :custom_field_section_id
    stored_attribute :default_value, store: :settings
    attribute :field_format
    attribute :formula
    attribute :has_comment
    attribute :is_filter
    attribute :is_for_all
    attribute :is_required do
      validate_non_true_for_some_formats
    end
    stored_attribute :max_length, store: :settings
    stored_attribute :min_length, store: :settings
    stored_attribute :max_value, store: :settings
    stored_attribute :min_value, store: :settings
    attribute :multi_value
    attribute :name
    attribute :possible_values
    stored_attribute :project_level_value_management, store: :settings do
      validate_project_level_value_management
    end
    attribute :project_specific_value_restriction do
      validate_project_specific_value_restriction
    end
    stored_attribute :regexp, store: :settings
    attribute :searchable
    stored_attribute :user_self_editable, store: :settings, readable: false
    attribute :visible_on_user_card
    attribute :type

    def validate_non_true_for_some_formats
      return unless %w[bool calculated_value].include?(field_format)

      errors.add(:is_required, :cannot_be_true) if is_required == true
    end

    def validate_project_specific_value_restriction
      return if project_specific_value_restriction.nil?

      if type != "WorkPackageCustomField" || %w[list hierarchy weighted_item_list].exclude?(field_format)
        errors.add(:project_specific_value_restriction, :not_supported)
      elsif model.project_specific_value_restriction_changed? && !EnterpriseToken.allows_to?(:project_specific_list_values)
        errors.add(:project_specific_value_restriction, :error_enterprise_only,
                   action: I18n.t("ee.features.project_specific_list_values"))
      end
    end

    def validate_project_level_value_management
      if project_level_value_management && project_specific_value_restriction.nil?
        errors.add(:project_level_value_management, :not_available_for_all_values)
      end

      validate_project_admin_flag_enterprise(:project_level_value_management)
    end

    def validate_project_admin_flag_enterprise(flag)
      return unless model.public_send(flag) && model.public_send(:"#{flag}_changed?")
      return if EnterpriseToken.allows_to?(:project_specific_list_values)

      errors.add(flag, :error_enterprise_only, action: I18n.t("ee.features.project_specific_list_values"))
    end
  end
end
