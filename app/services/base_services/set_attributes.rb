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

module BaseServices
  class SetAttributes < BaseCallable
    include Contracted

    def initialize(user:, model:, contract_class:, contract_options: {})
      super()

      self.user = user
      self.model = prepare_model(model)

      self.contract_class = contract_class
      self.contract_options = contract_options
    end

    def perform
      set_attributes(params)

      validate_and_result
    end

    private

    attr_accessor :user,
                  :model,
                  :contract_class

    def set_attributes(params)
      model.attributes = params

      set_default_attributes(params) if model.new_record?
      set_custom_values_to_validate(params) if model.customizable?
      ensure_default_attributes(params)
    end

    def set_default_attributes(_params)
      # nothing to do for now but a subclass may
    end

    def set_custom_values_to_validate(params)
      return model.deactivate_custom_field_validations! if contract_options[:skip_custom_field_validation]

      custom_field_ids = custom_field_ids_to_validate(params)

      # Update custom_values_to_validate when the custom field params are provided,
      # or when the model is a new record.
      # Otherwise keep them intact, so other services can still set them.
      return unless custom_field_ids.any?

      # Validate the custom values updated via the params only.
      set_custom_field_ids_to_validate(custom_field_ids)
    end

    def ensure_default_attributes(_params)
      # nothing to do for now but a subclass may
    end

    def validate_and_result
      success, errors = validate(model, user, options: contract_options)

      ServiceResult.new(success:,
                        errors:,
                        result: model)
    end

    def prepare_model(model)
      model.extend(OpenProject::ChangedBySystem)
      model
    end

    def custom_field_ids_to_validate(params)
      # Leave custom_field_ids_to_validate empty when the model is not persisted,
      # allowing the default behaviour to set the id's to be validated in the
      # model.custom_values_to_validate method.
      model.persisted? ? custom_field_ids_from(params) : []
    end

    def set_custom_field_ids_to_validate(custom_field_ids)
      model.custom_values_to_validate = model.custom_field_values.filter do |cv|
        custom_field_ids.include?(cv.custom_field_id)
      end
    end

    def custom_field_ids_from(params)
      # 1. Retrieve custom fields set via the accessor `wp.custom_field_1 = 1`
      custom_field_ids = params.keys.filter_map { |k| k[/^custom_field_(\d+)$/, 1]&.to_i }

      # 2. Retrieve custom fields set via the `wp.custom_field_values = { 1 => 1}` hash.
      if params[:custom_field_values]
        custom_field_ids += params[:custom_field_values].stringify_keys.keys.map(&:to_i)
      end

      custom_field_ids.uniq
    end
  end
end
