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

module Projects
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(params)
      super(set_attributes_params(params)).tap do
        set_status_code(params[:status_code]) if status_code_provided?(params)
      end
    end

    def set_attributes_params(params)
      # Remove fields that cannot be directly set
      filtered = params.except(:status_code)

      custom_field_value_params = filtered[:custom_field_values]
      return filtered unless custom_field_value_params

      calculated_field_ids = model.all_available_custom_fields
                                  .field_format_calculated_value
                                  .pluck(:id)

      filtered_cf_values = custom_field_value_params.reject do |id, _|
        id.to_s.to_i.in?(calculated_field_ids)
      end

      filtered.merge(custom_field_values: filtered_cf_values)
    end

    def set_default_attributes(attributes)
      attribute_keys = attributes.keys.map(&:to_s)

      set_default_public(attribute_keys.include?("public"))
      set_default_module_names(attribute_keys.include?("enabled_module_names"))
      set_default_types(attribute_keys.include?("types") || attribute_keys.include?("type_ids"))
      set_default_active_work_package_custom_fields(attribute_keys.include?("work_package_custom_fields"))
      set_default_show_work_package_attachments(attribute_keys.include?("deactivate_work_package_attachments"))
    end

    def set_default_public(provided)
      model.public = Setting.default_projects_public? unless provided
    end

    def set_default_module_names(provided)
      model.enabled_module_names = Setting.default_projects_modules if !provided && model.enabled_module_names.empty?
    end

    def set_default_show_work_package_attachments(provided)
      model.deactivate_work_package_attachments = !Setting.show_work_package_attachments? unless provided
    end

    def set_default_types(provided)
      model.types = ::Type.default if !provided && model.types.empty?
    end

    def set_default_active_work_package_custom_fields(provided)
      return if provided

      model.work_package_custom_fields = WorkPackageCustomField
        .joins(:types)
        .where(types: { id: model.type_ids })
        .distinct
    end

    def status_code_provided?(params)
      params.key?(:status_code)
    end

    def set_status_code(status_code)
      if faulty_code?(status_code)
        # set an arbitrary status code first to get rails internal into correct state
        model.status_code = first_not_set_code
        # hack into rails internals to set faulty code
        code_attributes = model.instance_variable_get(:@attributes)["status_code"]
        code_attributes.instance_variable_set(:@value_before_type_cast, status_code)
        code_attributes.instance_variable_set(:@value, status_code)
      else
        model.status_code = status_code
      end
    end

    def faulty_code?(status_code)
      status_code && Project.status_codes.keys.exclude?(status_code.to_s)
    end

    def first_not_set_code
      (Project.status_codes.keys - [model.status_code]).first
    end

    def set_custom_values_to_validate(params)
      # In case of new records, validate custom fields that are enabled for all projects
      # and also required.
      if model.new_record? && !contract_options[:skip_custom_field_validation]
        set_custom_field_ids_to_validate(model.available_custom_fields.for_all.required.pluck(:id))
      else
        super
      end
    end
  end
end
