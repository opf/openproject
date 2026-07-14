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
    end

    def call
      return render(Primer::Box.new(**swatch_arguments)) unless show_value?

      render(Primer::OpenProject::FlexLayout.new(classes: "op-color-swatch--with-value", align_items: :center)) do |flex|
        flex.with_column do
          render(Primer::Box.new(**swatch_arguments))
        end

        flex.with_column do
          render(Primer::Beta::Text.new(tag: :span)) { hexcode }
        end
      end
    end

    private

    attr_reader :hexcode

    def show_value?
      @show_value
    end

    def swatch_arguments
      @system_arguments.merge(
        tag: :span,
        classes: helpers.class_names("op-color-swatch", @system_arguments[:classes]),
        aria: @system_arguments.fetch(:aria, {}).merge(hidden: true),
        style: [@system_arguments[:style], "background-color: #{hexcode}"].compact.join("; ")
      )
    end
  end
end
