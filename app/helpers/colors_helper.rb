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

module ColorsHelper
  include Primer::JoinStyleArgumentsHelper

  def options_for_colors(colored_thing)
    colors = []
    Color.find_each do |c|
      options = {}
      options[:name] = c.name
      options[:value] = c.id
      options[:selected] = true if c.id == colored_thing.color_id

      colors.push(options)
    end
    colors.to_json
  end

  def selected_color(colored_thing)
    colored_thing.color_id
  end

  #
  # Emits one rule per entry declaring the color as CSS custom properties. The rules that
  # consume them (`__hl_background`, `__hl_foreground`, `__hl_dot`) are static and live in
  # the `Highlighting colors` section of `frontend/src/global_styles/layout/_colors.sass`.
  ##
  def resource_color_css(name, scope)
    scope.map { |entry| color_variables_css(name, entry) }.join("\n")
  end

  def hl_color_class(name, model)
    id = model.respond_to?(:id) ? model.id : model
    "__hl_#{name}_#{id}"
  end

  def hl_background_class(name, model)
    "__hl_background #{hl_color_class(name, model)}"
  end

  def hl_foreground_class(name, model)
    "__hl_foreground #{hl_color_class(name, model)}"
  end

  def hl_dot_class(name, model)
    "__hl_dot #{hl_color_class(name, model)}"
  end

  def icon_for_color(color, options = {})
    return unless color&.valid_attribute?(:hexcode)

    style = join_style_arguments(
      "background-color: #{color.hexcode}",
      "border-color: #{color.darken(0.5)}50",
      options[:style]
    )

    options.merge!(class: "color--preview #{options[:class]}",
                   title: color.name,
                   style:)

    content_tag(:span, " ", options)
  end

  def color_by_variable(variable)
    DesignColor.find_by(variable:)&.hexcode
  end

  private

  def color_variables_css(name, entry)
    color = entry.is_a?(::Color) ? entry : entry.color
    selector = ".#{hl_color_class(name, entry)}"

    # Without a color the dot would still occupy space, while background and foreground
    # neutralize themselves: their declarations reference the undeclared --hl-color and
    # become invalid at computed-value time.
    return "#{selector}.__hl_dot::before { display: none }" if color.nil?

    "#{selector} { --hl-color: #{color.hexcode}; --hl-perceived-lightness: #{color.perceived_lightness} }"
  end
end
