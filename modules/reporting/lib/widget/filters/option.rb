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

##
# Accepts option :content, which expects an enumerable of [name, id, *args]
# as it would appear in a filters available values. If given, it renders the
# option-tags from the content array instead of the filters available values.
class Widget::Filters::Option < Widget::Filters::Base
  def render
    options = content(@options[:content] || filter_class.available_values)
    write safe_join(options)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
  def content(values)
    first = true
    values.map do |name, id, *args|
      options = args.first || {} # optional configuration for values
      level = options[:level] # nesting_level is optional for values
      name = I18n.t(name) if name.is_a? Symbol
      name = I18n.t(:label_none) if name.empty?
      name_prefix = (level && level > 0 ? "#{' ' * 2 * level}> " : "")
      if options[:optgroup]
        tag :optgroup, label: I18n.t(:label_sector)
      else
        opts = { value: id }
        if (Array(filter.values).map(&:to_s).include? id.to_s) || (first && Array(filter.values).empty?)
          opts[:selected] = "selected"
        end
        first = false
        content_tag(:option, opts) { name_prefix + name }
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity
end
