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

module CustomStyles
  class DesignColorDialogComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    attr_reader :variable, :color_label, :instruction, :value, :placeholder,
                :form_url, :form_method, :param_name, :scope_name_to_model, :field_data

    def initialize(variable:, label:, instruction:, value:, placeholder:, form_url:, param_name:,
                   form_method: :post, scope_name_to_model: false, field_data: {})
      super()

      @variable = variable
      @color_label = label
      @instruction = instruction
      @value = value
      @placeholder = placeholder
      @form_url = form_url
      @form_method = form_method
      @param_name = param_name
      @scope_name_to_model = scope_name_to_model
      @field_data = field_data
    end

    private

    def dialog_id = "design-color-#{variable}-dialog"

    def form_id = "design-color-#{variable}-form"

    def form_arguments
      {
        url: form_url,
        method: form_method,
        id: form_id,
        data: { turbo: false }
      }
    end

    def field_arguments
      {
        name: param_name,
        id: "design_colors_#{variable}",
        label: color_label,
        visually_hide_label: true,
        caption: instruction,
        value:,
        placeholder:,
        input_width: :medium,
        scope_name_to_model:,
        data: field_data
      }
    end
  end
end
