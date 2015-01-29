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

class Widget::GroupBys < Widget::Base
  def render_options(group_by_ary)
    group_by_ary.sort_by(&:label).map do |group_by|
      next unless group_by.selectable?
      content_tag :option, value: group_by.underscore_name, :'data-label' => "#{CGI::escapeHTML(h(group_by.label))}" do
        h(group_by.label)
      end
    end.join.html_safe
  end

  def render_group_caption(_type)
    content_tag :span do
      out = content_tag :span, class: 'arrow in_row arrow_group_by_caption' do
        '' # cannot use tag here as it would generate <span ... /> which leads to wrong interpretation in most browsers
      end
      out.html_safe
    end
  end

  def render_group(type, initially_selected, show_help = false)
    initially_selected = initially_selected.map do |group_by|
      [group_by.class.underscore_name, h(group_by.class.label)]
    end

    content_tag :fieldset,
                id: "group_by_#{type}",
                class: 'drag_target drag_container',
                :'data-initially-selected' => initially_selected.to_json.gsub('"', "'") do
      out = content_tag :legend, l(:"label_#{type}"), class: 'in_row group_by_caption'

      out += render_group_caption type

      out += label_tag "add_group_by_#{type}",
                       l(:"label_group_by_add"),
                       class: 'hidden-for-sighted'

      out += content_tag :select, id: "add_group_by_#{type}", class: 'advanced-filters--select' do
        content = content_tag :option, "-- #{l(:label_group_by_add)} --", value: ''

        content += engine::GroupBy.all_grouped.sort_by do |label, _group_by_ary|
          l(label)
        end.map do |label, group_by_ary|
          content_tag :optgroup, label: h(l(label)) do
            render_options group_by_ary
          end
        end.join.html_safe
        content
      end

      if show_help
        out += maybe_with_help icon: { class: 'group-by-icon' },
                               tooltip: { class: 'group-by-tip' },
                               instant_write: false
      end

      out
    end
  end

  def render
    write(content_tag(:div, id: 'group_by_area') do
      out =  render_group 'columns', @subject.group_bys(:column), true
      out += render_group 'rows', @subject.group_bys(:row)
      out += image_tag 'reporting_engine/remove.gif',
                       id: 'hidden_remove_img',
                       style: 'display:none',
                       class: 'reporting_hidden_group_remove_image'
      out.html_safe
    end)
  end
end
