#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

class Widget::GroupBys < Widget::Base
  def render_options(group_by_ary)
    group_by_ary.sort_by(&:label).map do |group_by|
      next unless group_by.selectable?
      content_tag :option, value: group_by.underscore_name, :'data-label' => "#{CGI::escapeHTML(h(group_by.label))}" do
        h(group_by.label)
      end
    end.join.html_safe
  end

  def render_group(type, initially_selected)
    initially_selected = initially_selected.map do |group_by|
      [group_by.class.underscore_name, h(group_by.class.label)]
    end

    content_tag :fieldset do

      legend = content_tag :legend, I18n.t("reporting.group_by.selected_#{type}"), class: 'hidden-for-sighted'

      container = content_tag :div,
                id: "group-by--#{type}",
                class: 'group-by--container grid-block',
                :'data-initially-selected' => initially_selected.to_json.gsub('"', "'") do
        out = content_tag :span, class: 'group-by--caption grid-content shrink' do
          content_tag :span do
            l(:"label_#{type}")
          end
        end

        out += content_tag :span, '', id: "group-by--selected-#{type}", class: 'group-by--selected-elements grid-block'

        out += content_tag :span,
                           class: 'group-by--control grid-content shrink' do
          label = label_tag "group-by--add-#{type}",
                         l(:"label_group_by_add") + ' ' +
                         I18n.t('js.filter.description.text_open_filter'),
                         class: 'hidden-for-sighted'

          label += content_tag :select, id: "group-by--add-#{type}", class: 'advanced-filters--select' do
            content = content_tag :option, l(:label_group_by_add), value: ''

            content += engine::GroupBy.all_grouped.sort_by do |label, _group_by_ary|
              l(label)
            end.map do |label, group_by_ary|
              content_tag :optgroup, label: h(l(label)) do
                render_options group_by_ary
              end
            end.join.html_safe
            content
          end

          label
        end

        out
      end

      legend + container
    end
  end

  def render
    write(content_tag(:div, id: 'group-by--area', class: 'autoscroll') do
      out =  render_group 'columns', @subject.group_bys(:column)
      out += render_group 'rows', @subject.group_bys(:row)
      out.html_safe
    end)
  end
end
