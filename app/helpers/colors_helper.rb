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
  # Styles to display colors itself (e.g. for the colors autocompleter)
  ##
  def color_css
    Color.find_each do |color|
      set_background_colors_for class_name: ".__hl_inline_color_#{color.id}_dot::before", hexcode: color.hexcode
      set_foreground_colors_for class_name: ".__hl_inline_color_#{color.id}_text", hexcode: color.hexcode
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

      if name === "type"
        set_foreground_colors_for class_name: ".__hl_inline_#{name}_#{entry.id}", hexcode: color.hexcode
      else
        set_background_colors_for class_name: ".__hl_inline_#{name}_#{entry.id}::before", hexcode: color.hexcode
      end

      set_background_colors_for class_name: ".__hl_background_#{name}_#{entry.id}", hexcode: color.hexcode
    end
  end

  def icon_for_color(color, options = {})
    return unless color

    options.merge! class: "color--preview " + options[:class].to_s,
                   title: color.name,
                   style: "background-color: #{color.hexcode};" + options[:style].to_s

    content_tag(:span, " ", options)
  end

  def color_by_variable(variable)
    DesignColor.find_by(variable:)&.hexcode
  end

  def set_background_colors_for(class_name:, hexcode:)
    mode = User.current.pref.theme.split("_", 2)[0]

    concat "#{class_name} { #{default_color_styles(hexcode)} }"
    if mode == "dark"
      concat "#{class_name} { #{default_variables_dark} }"
      concat "#{class_name} { #{highlighted_background_dark} }"
    else
      concat "#{class_name} { #{default_variables_light} }"
      concat "#{class_name} { #{highlighted_background_light} }"
    end
  end

  def set_foreground_colors_for(class_name:, hexcode:)
    mode = User.current.pref.theme.split("_", 2)[0]

    concat "#{class_name} { #{default_color_styles(hexcode)} }"
    if mode == "dark"
      concat "#{class_name} { #{default_variables_dark} }"
      concat "#{class_name} { #{highlighted_foreground_dark} }"
    else
      concat "#{class_name} { #{default_variables_light} }"
      concat "#{class_name} { #{highlighted_foreground_light} }"
    end
  end

  # rubocop:disable Layout/LineLength
  def default_color_styles(hex)
    color = ColorConversion::Color.new(hex)
    rgb = color.rgb
    hsl = color.hsl

    "--color-r: #{rgb[:r]};
     --color-g: #{rgb[:g]};
     --color-b: #{rgb[:b]};
     --color-h: #{hsl[:h]};
     --color-s: #{hsl[:s]};
     --color-l: #{hsl[:l]};
     --perceived-lightness: calc( ((var(--color-r) * 0.2126) + (var(--color-g) * 0.7152) + (var(--color-b) * 0.0722)) / 255 );
     --lightness-switch: max(0, min(calc((1/(var(--lightness-threshold) - var(--perceived-lightness)))), 1));"
  end

  def default_variables_dark
    "--lightness-threshold: 0.6;
     --background-alpha: 0.18;
     --lighten-by: calc(((var(--lightness-threshold) - var(--perceived-lightness)) * 100) * var(--lightness-switch));"
  end

  def default_variables_light
    "--lightness-threshold: 0.453;"
  end

  def highlighted_background_dark
    "color: hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%)) !important;
     background: rgba(var(--color-r), var(--color-g), var(--color-b), var(--background-alpha)) !important;
     border: 1px solid hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%)) !important;"
  end

  def highlighted_background_light
    style = "color: hsl(0deg, 0%, calc(var(--lightness-switch) * 100%)) !important;
     background: rgb(var(--color-r), var(--color-g), var(--color-b)) !important;"
    mode = User.current.pref.theme

    if mode == "light_high_contrast"
      style += "border: 1px solid hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - 75) * 1%), 1) !important;"
    else
      style += "border: 1px solid hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - 15) * 1%)) !important;"
    end

    style
  end

  def highlighted_foreground_dark
    "color: hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%), 1) !important;"
  end

  def highlighted_foreground_light
    mode = User.current.pref.theme

    if mode == "light_high_contrast"
      "color: hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - (var(--color-l) * 0.5)) * 1%), 1) !important;"
    else
      "color: hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - (var(--color-l) * 0.22)) * 1%), 1) !important;"
    end
  end
  # rubocop:enable Layout/LineLength
end
