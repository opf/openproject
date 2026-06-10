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
  class UpdateService < ::BaseServices::Update
    protected

    def instance_class = Type

    def validate_params
      # Only set attribute groups when it exists (Regression #28400)
      if params[:attribute_groups]
        result = set_attribute_groups(params)
        return result if result.failure?
      end

      set_active_custom_fields
      set_active_custom_fields_for_project_ids(params[:project_ids]) if params[:project_ids].present?

      super
    end

    private

    def default_contract_class = UpdateSettingsContract

    def set_attribute_groups(params)
      normalize_result = normalize_attribute_groups_param(params[:attribute_groups])
      return normalize_result if normalize_result.failure?

      assign_result = assign_attribute_groups(normalize_result.result)
      return assign_result if assign_result.failure?

      params.delete(:attribute_groups)
      ServiceResult.success(result: model)
    end

    def normalize_attribute_groups_param(attribute_groups)
      parsed_groups = case attribute_groups
                      when String
                        JSON.parse(attribute_groups)
                      else
                        attribute_groups
                      end

      return invalid_attribute_groups_result unless parsed_groups.is_a?(Array)

      ServiceResult.success(result: parsed_groups.map(&:deep_symbolize_keys))
    rescue JSON::ParserError
      invalid_attribute_groups_result
    end

    def assign_attribute_groups(attribute_groups)
      if attribute_groups.empty?
        model.reset_attribute_groups
      else
        transform_result = AttributeGroups::Transformer.new(groups: attribute_groups, user: user).call
        return transform_result if transform_result.failure?

        model.attribute_groups = transform_result.result
      end

      ServiceResult.success(result: model)
    end

    def invalid_attribute_groups_result
      model.errors.clear
      model.errors.add(:attribute_groups, I18n.t("types.edit.form_configuration.invalid_attribute_groups"))

      ServiceResult.failure(result: model, errors: model.errors)
    end

    ##
    # Syncs attribute group settings for custom fields with enabled custom fields
    # for this type. If a custom field is not in a group, it is removed from the
    # custom_field_ids list.
    def set_active_custom_fields
      model.custom_field_ids = model.attribute_groups
                                  .flat_map(&:members)
                                  .filter_map do |attr|
                                    if CustomField.custom_field_attribute?(attr)
                                      attr.delete_prefix("custom_field_").to_i
                                    end
                                  end.uniq
    end

    def set_active_custom_fields_for_project_ids(project_ids)
      new_project_ids_to_activate_cfs = project_ids.reject(&:empty?).map(&:to_i) - model.project_ids

      values = Project
                 .where(id: new_project_ids_to_activate_cfs)
                 .to_a
                 .product(model.custom_field_ids)
                 .map { |p, cf_ids| { project_id: p.id, custom_field_id: cf_ids } }

      return if values.empty?

      CustomFieldsProject.insert_all(values)
    end
  end
end
