#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module ColorsHelper
  def options_for_colors(colored_thing, default_label: I18n.t('colors.label_no_color'), default_color: '')
    s = content_tag(:option, default_label, value: default_color)
    Color.find_each do |c|
      options = {}
      options[:value] = c.id
      options[:data] = {
        color: c.hexcode,
        bright: c.bright?,
        background: c.contrasting_color(light_color: 'transparent')
      }
      options[:selected] = true if c.id == colored_thing.color_id

      s << content_tag(:option, c.name, options)
    end
    s
  end

  def darken_color(hex_color, amount = 0.4)
    hex_color = hex_color.delete('#')
    rgb = hex_color.scan(/../).map(&:hex)
    rgb[0] = (rgb[0].to_i * amount).round
    rgb[1] = (rgb[1].to_i * amount).round
    rgb[2] = (rgb[2].to_i * amount).round
    "#%02x%02x%02x" % rgb
  end

  def colored_text(color)
    background = color.contrasting_color(dark_color: '#333', light_color: 'transparent')
    style = "background-color: #{background}; color: #{color.hexcode}"
    content_tag(:span, color.hexcode, class: 'color--text-preview', style: style)
  end

  def resource_color_css(name, scope)
    scope.includes(:color).find_each do |entry|
      color = entry.color

      if color.nil?
        concat ".__hl_dot_#{name}_#{entry.id}::before { display: none }\n"
        next
      end

      styles = color.color_styles

      inline_style = styles.map { |k,v| "#{k}:#{v} !important"}.join(';')
      row_style = "background-color: #{color.hexcode} !important;"

      border_color = color.bright? ? '#555555' : color.hexcode

      concat ".__hl_inl_#{name}_#{entry.id} { #{inline_style}; }\n"
      concat ".__hl_dot_#{name}_#{entry.id}::before { #{inline_style}; border-color: #{border_color}; }\n"
      concat ".__hl_row_#{name}_#{entry.id} { #{row_style}; }\n"

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
end
