# frozen_string_literal: true

# -- copyright
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
# ++

module CustomStyles
  class DesignColorDialogComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    attr_reader :design_color, :color_label, :instruction, :hexcode

    def initialize(design_color:, label:, instruction:, hexcode:)
      super()

      @design_color = design_color
      @color_label = label
      @instruction = instruction
      @hexcode = hexcode
    end

    private

    def variable = design_color.variable

    def dialog_id = "design-color-#{variable}-dialog"

    def form_id = "design-color-#{variable}-form"

    def form_arguments
      {
        url: url_helpers.update_design_colors_path,
        method: :post,
        id: form_id,
        data: { turbo: false }
      }
    end

    def field_arguments
      {
        name: "design_colors[]#{variable}",
        id: "design_colors_#{variable}",
        label: color_label,
        visually_hide_label: true,
        caption: instruction,
        value: design_color.hexcode,
        placeholder: hexcode,
        input_width: :medium,
        scope_name_to_model: false,
        data: { variable_name: variable }
      }
    end
  end
end
