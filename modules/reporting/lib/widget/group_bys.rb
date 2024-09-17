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

class Widget::GroupBys < Widget::Base
  # rubocop:disable Metrics/AbcSize
  def render_options(group_by_ary)
    options = group_by_ary.sort_by(&:label).map do |group_by|
      next unless group_by.selectable?

      label_text = CGI::escapeHTML(h(group_by.label)).to_s
      option_tags = { value: group_by.underscore_name, "data-label": label_text }
      option_tags[:title] = label_text if group_by.label.length > 40
      content_tag :option, option_tags do
        h(truncate_single_line(group_by.label, length: 40))
      end
    end

    safe_join(options)
  end

  def render_group(type, initially_selected)
    initially_selected = initially_selected.map do |group_by|
      [group_by.class.underscore_name, h(group_by.class.label)]
    end

    content_tag :fieldset do
      legend = content_tag :legend, I18n.t("reporting.group_by.selected_#{type}"), class: "hidden-for-sighted"

      container = content_tag :div,
                              id: "group-by--#{type}",
                              class: "group-by--container grid-block",
                              "data-initially-selected": initially_selected.to_json.tr('"', "'") do
        out = content_tag :span, class: "group-by--caption grid-content shrink" do
          content_tag :span do
            I18n.t(:"label_#{type}")
          end
        end

        out += content_tag :span, "", id: "group-by--selected-#{type}", class: "group-by--selected-elements grid-block"

        out += content_tag :span,
                           class: "group-by--control grid-content shrink" do
          label = label_tag "group-by--add-#{type}",
                            "#{I18n.t(:label_group_by_add)} #{I18n.t('js.filter.description.text_open_filter')}",
                            class: "hidden-for-sighted"

          label += content_tag :select, id: "group-by--add-#{type}", class: "advanced-filters--select" do
            content = content_tag :option, I18n.t(:label_group_by_add), value: "", disabled: true, selected: true

            sort_by_options = engine::GroupBy.all_grouped.sort_by do |i18n_key, _group_by_ary|
              I18n.t(i18n_key)
            end.map do |i18n_key, group_by_ary| # rubocop:disable Style/MultilineBlockChain
              content_tag :optgroup, label: h(I18n.t(i18n_key)) do
                render_options group_by_ary
              end
            end
            content += safe_join(sort_by_options)
            content
          end

          label
        end

        out
      end

      legend + container
    end
  end
  # rubocop:enable Metrics/AbcSize

  def render
    write(content_tag(:div, id: "group-by--area", class: "autoscroll") do
      out = "".html_safe
      out << render_group("columns", @subject.group_bys(:column))
      out << render_group("rows", @subject.group_bys(:row))
      out
    end)
  end
end
