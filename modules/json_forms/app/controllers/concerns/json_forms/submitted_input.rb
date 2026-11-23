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

module JsonForms
  # Reads the data submitted through a JsonForms::InputForm.
  module SubmittedInput
    private

    def json_forms_input(schema, scope: :input)
      raw = params.fetch(scope, {}).permit!.to_h
      FormData.coerce(schema, raw) || {}
    end

    # For the refresh action: the submitted data with a clicked Add/Remove button applied.
    # A rejected property name is available from `json_forms_refresh_errors`, for the form's `errors:`.
    def json_forms_refreshed_input(schema, scope: :input)
      input = json_forms_input(schema, scope:)
      operation = params[:_operation].to_s
      return input if operation.blank?

      data = FormData.apply_operation(schema, input, operation, property_name: params[property_name_param(operation)])
      @json_forms_added_property_param = property_name_param(operation) if operation.start_with?("add_property:")
      data
    rescue FormData::InvalidPropertyName => e
      @json_forms_refresh_errors = { property_name_param(operation) => e.message }
      input
    end

    def json_forms_refresh_errors
      @json_forms_refresh_errors || {}
    end

    # What the form keeps besides the data (names typed for new properties, selected tabs), for its `state:`.
    def json_forms_state
      params.to_unsafe_h
            .select { |key, _| InputForm::STATE_PARAMS.any? { key.start_with?(it) } }
            .except(@json_forms_added_property_param)
    end

    def property_name_param(operation)
      "#{InputForm::NEW_PROPERTY_PARAM}#{operation.split(':', 2).last}"
    end
  end
end
