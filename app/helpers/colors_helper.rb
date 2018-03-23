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
  def options_for_colors(colored_thing)
    s = content_tag(:option, '')
    colored_thing.available_colors.each do |c|
      options = {}
      options[:value] = c.id
      options[:selected] = 'selected' if c.id == colored_thing.color_id

      options[:style] = "background-color: #{c.hexcode}; color: #{c.text_hexcode}"

      s << content_tag(:option, h(c.name), options)
    end
    s
  end

  def icon_for_color(color, options = {})
    return unless color

    options = options.merge(class: 'color-preview ' + options[:class].to_s,
                            style: "background-color: #{color.hexcode};" + options[:style].to_s)

    content_tag(:span, ' ', options)
  end
end
