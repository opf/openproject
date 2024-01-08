#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  def options_for_colors(colored_thing)
    colors = []
    Color.find_each do |c|
      options = {}
      options[:name] = c.name
      options[:value] = c.id
      options[:data] = {
        color: c.hexcode,
        bright: c.bright?,
        dark: c.dark?,
        background: c.contrasting_color(light_color: 'transparent')
      }
      options[:selected] = true if c.id == colored_thing.color_id

      colors.push(options)
    end
    colors.to_json
  end

  def selected_color(colored_thing)
    colored_thing.color_id
  end

  def colored_text(color)
    background = color.contrasting_color(dark_color: '#333', light_color: 'transparent')
    style = "background-color: #{background}; color: #{color.hexcode}"
    content_tag(:span, color.hexcode, class: 'color--text-preview', style:)
  end

  #
  # Styles to display colors itself (e.g. for the colors autocompleter)
  ##
  def color_css
    Color.find_each do |color|
      concat ".__hl_inline_color_#{color.id}_dot::before { background-color: #{color.hexcode} !important;}"
      concat ".__hl_inline_color_#{color.id}_dot::before { border: 1px solid #555555 !important;}" if color.bright?
      concat ".__hl_inline_color_#{color.id}_text { color: #{color.hexcode} !important;}"
      concat ".__hl_inline_color_#{color.id}_text { -webkit-text-stroke: 0.5px grey; text-stroke: 0.5px grey;}" if color.super_bright?
    end
  end

  #
  # Styles to display the color of attributes (type, status etc.) for example in the WP view
  ##
  def resource_color_css(name, scope)
    scope.includes(:color).find_each do |entry|
      color = entry.color

      if color.nil?
        concat ".__hl_inline_#{name}_#{entry.id}::before { display: none }\n"
        next
      end

      styles = color.color_styles
      background_style = styles.map { |k, v| "#{k}:#{v} !important" }.join(';')

      if name === 'type'
        concat ".__hl_inline_#{name}_#{entry.id} { color: #{color.hexcode} !important;}"
        concat ".__hl_inline_#{name}_#{entry.id} { -webkit-text-stroke: 0.5px grey;}" if color.super_bright?

        border_color = color.super_bright? ? '#555555' : color.hexcode
        concat ".__hl_background_#{name}_#{entry.id} { border-color: #{border_color} !important; }"
      else
        border_color = color.bright? ? '#555555' : color.hexcode
        concat ".__hl_inline_#{name}_#{entry.id}::before { #{background_style}; border-color: #{border_color}; }\n"
      end

      concat ".__hl_background_#{name}_#{entry.id} { #{background_style}; }\n"

      # Mark color as bright through CSS variable
      # so it can be used to add a separate -bright class
      unless color.bright?
        concat ":root { --hl-#{name}-#{entry.id}-dark: #{styles[:color]} }\n"
      end
    end
  end

  def icon_for_color(color, options = {})
    return unless color

    options.merge! class: 'color--preview ' + options[:class].to_s,
                   title: color.name,
                   style: "background-color: #{color.hexcode};" + options[:style].to_s

    content_tag(:span, ' ', options)
  end

  def color_by_variable(variable)
    DesignColor.find_by(variable:)&.hexcode
  end
end
