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

class Widget::Filters::MultiValues < Widget::Filters::Base
  def render
    write(content_tag(:div, id: "#{filter_class.underscore_name}_arg_1", class: "advanced-filters--filter-value") do
      select_options = {  "data-remote-url": url_for(action: "available_values"),
                          "data-initially-selected": JSON::dump(Array(filter.values).flatten),
                          style: "vertical-align: top;", # FIXME: Do CSS
                          name: "values[#{filter_class.underscore_name}][]",
                          "data-loading": @options[:lazy] ? "ajax" : "",
                          id: "#{filter_class.underscore_name}_arg_1_val",
                          class: "form--select filter-value",
                          "data-filter-name": filter_class.underscore_name }
      box_content = "".html_safe
      label = label_tag "#{filter_class.underscore_name}_arg_1_val",
                        h(filter_class.label) + " " + I18n.t(:label_filter_value),
                        class: "hidden-for-sighted"

      box = content_tag :select, select_options, id: "#{filter_class.underscore_name}_select_1" do
        render_widget Widget::Filters::Option, filter, to: box_content unless @options[:lazy]
      end
      plus = content_tag :a,
                         href: "#",
                         class: "form-label filter_multi-select -transparent",
                         "data-filter-name": filter_class.underscore_name,
                         title: I18n.t(:description_multi_select) do
        content_tag :span,
                    "",
                    class: "icon-context icon-button icon-add icon4",
                    title: I18n.t(:label_enable_multi_select) do
          content_tag :span, I18n.t(:label_enable_multi_select), class: "hidden-for-sighted"
        end
      end

      content_tag(:span, class: "inline-label") do
        label + box + plus
      end
    end)
  end
end
