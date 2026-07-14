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

module Colors
  class SwatchComponent < ApplicationComponent
    def initialize(hexcode:, show_value: false, **system_arguments)
      super()

      @hexcode = hexcode
      @show_value = show_value
      @system_arguments = system_arguments
      @system_arguments[:align_items] ||= :center

      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "op-color-swatch"
      )
    end

    def call
      render(Primer::OpenProject::FlexLayout.new(**@system_arguments)) do |flex|
        flex.with_column do
          render(Primer::Box.new(**swatch_arguments))
        end

        if show_value?
          flex.with_column do
            render(Primer::Beta::Text.new(tag: :span, ml: 2)) { hexcode }
          end
        end
      end
    end

    private

    attr_reader :hexcode

    def show_value?
      @show_value
    end

    def swatch_arguments
      {
        tag: :span,
        classes: "op-color-swatch--indicator",
        aria: { hidden: true },
        style: "background-color: #{hexcode}"
      }
    end
  end
end
