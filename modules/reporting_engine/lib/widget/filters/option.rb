#-- copyright
# ReportingEngine
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

##
# Accepts option :content, which expects an enumerable of [name, id, *args]
# as it would appear in a filters available values. If given, it renders the
# option-tags from the content array instead of the filters available values.
# make sure to require Widget::Filters::Base first because otherwise
# ruby might find Base within Widget and Rails will not load it
require_dependency 'widget/filters/base'
class Widget::Filters::Option < Widget::Filters::Base
  def render
    first = true
    write((@options[:content] || filter_class.available_values).map do |name, id, *args|
      options = args.first || {} # optional configuration for values
      level = options[:level] # nesting_level is optional for values
      name = l(name) if name.is_a? Symbol
      name = name.empty? ? l(:label_none) : name
      name_prefix = ((level && level > 0) ? (' ' * 2 * level + '> ') : '')
      unless options[:optgroup]
        opts = { value: id }
        if (Array(filter.values).map(&:to_s).include? id.to_s) || (first && Array(filter.values).empty?)
          opts[:selected] = 'selected'
        end
        first = false
        content_tag(:option, opts) { name_prefix + name }
      else
        tag :optgroup, label: l(:label_sector)
      end
    end.join.html_safe)
  end
end
