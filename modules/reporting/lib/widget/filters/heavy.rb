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

# FIXME: This basically is the MultiValues-Filter, except that we do not show
#        The select-box. This way we allow our JS to pretend this is just another
#        Filter. This is overhead...
#        But well this is again one of those temporary solutions.
class Widget::Filters::Heavy < Widget::Filters::Base
  # rubocop:disable Metrics/AbcSize
  def render
    # TODO: sometimes filter.values is of the form [["3"]] and sometimes ["3"].
    #       (using cost reporting)
    #       this might be a bug - further research would be fine
    values = filter.values.first.is_a?(Array) ? filter.values.first : filter.values
    opts = Array(values).empty? ? [] : values.map { |i| filter_class.label_for_value(i.to_i) }
    div = content_tag :div, id: "#{filter_class.underscore_name}_arg_1", class: "advanced-filters--filter-value hidden" do
      select_options = {  "data-remote-url": url_for(action: "available_values"),
                          "data-initially-selected": JSON::dump(Array(filter.values).flatten),
                          name: "values[#{filter_class.underscore_name}][]",
                          "data-loading": "",
                          id: "#{filter_class.underscore_name}_arg_1_val",
                          class: "advanced-filters--select filter-value",
                          "data-filter-name": filter_class.underscore_name }
      box = content_tag :select, select_options do
        render_widget Widget::Filters::Option, filter, to: "", content: opts
      end
      box
    end
    alternate_text = safe_join(opts.map(&:first), ", ")
    write(div + content_tag(:label, alternate_text))
  end
  # rubocop:enable Metrics/AbcSize
end
