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
  # A BorderBoxList row showing a color's label/instruction, its current
  # swatch, and an edit dialog (see DesignColorDialogComponent).
  class ColorListItemComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    attr_reader :color_label, :instruction, :hexcode, :show_value, :dialog_arguments

    def initialize(label:, instruction:, hexcode:, dialog_arguments:, show_value: hexcode.present?)
      super()

      @color_label = label
      @instruction = instruction
      @hexcode = hexcode
      @show_value = show_value
      @dialog_arguments = dialog_arguments
    end
  end
end
