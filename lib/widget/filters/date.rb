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

# make sure to require Widget::Filters::Base first because otherwise
# ruby might find Base within Widget and Rails will not load it
require_dependency 'widget/filters/base'
class Widget::Filters::Date < Widget::Filters::Base
  def render
    @calendar_headers_tags_included = true

    name = "values[#{filter_class.underscore_name}][]"
    id_prefix = "#{filter_class.underscore_name}_"

    write(content_tag(:td) do
      label1 = label_tag "#{id_prefix}arg_1_val",
                         h(filter_class.label) + ' ' + l(:label_filter_value),
                         class: 'hidden-for-sighted'

      arg1 = content_tag :span, id: "#{id_prefix}arg_1", class: 'filter_values' do
        text1 = text_field_tag name, @filter.values.first.to_s,
                               size: 10,
                               class: 'select-small',
                               id: "#{id_prefix}arg_1_val",
                               :'data-type' => 'date'
        cal1 = calendar_for("#{id_prefix}arg_1_val")
        label1 + text1 + cal1
      end
      label2 = label_tag "#{id_prefix}arg_2_val",
                         h(filter_class.label) + ' ' + l(:label_filter_value),
                         class: 'hidden-for-sighted'

      arg2 = content_tag :span, id: "#{id_prefix}arg_2", class: 'between_tags' do
        text2 = text_field_tag "#{name}", @filter.values.second.to_s,
                               size: 10,
                               class: 'select-small',
                               id: "#{id_prefix}arg_2_val",
                               :'data-type' => 'date'
        cal2 = calendar_for "#{id_prefix}arg_2_val"
        label2 + text2 + cal2
      end
      arg1 + arg2
    end)
  end
end
