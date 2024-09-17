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

class Widget::Filters::Operators < Widget::Filters::Base
  # rubocop:disable Metrics/AbcSize
  def render
    write(content_tag(:div, class: "advanced-filters--filter-operator") do
      hide_select_box = filter_class.available_operators.count == 1 || filter_class.heavy?
      options = { class: "advanced-filters--select filters-select filter_operator",
                  id: "operators[#{filter_class.underscore_name}]",
                  name: "operators[#{filter_class.underscore_name}]",
                  "data-filter-name": filter_class.underscore_name }
      options[:style] = "display: none" if hide_select_box

      select_box = content_tag :select, options do
        operators = filter_class.available_operators.map do |o|
          opts = { value: h(o.to_s), "data-arity": o.arity }
          opts.reverse_merge! "data-forced": o.forced if o.forced?
          opts[:selected] = "selected" if filter.operator.to_s == o.to_s
          content_tag(:option, opts) { h(I18n.t(o.label)) }
        end
        safe_join(operators)
      end
      label1 = content_tag :label,
                           hidden_for_sighted_label,
                           for: "operators[#{filter_class.underscore_name}]",
                           class: "hidden-for-sighted"
      label = content_tag :label do
        if filter_class.available_operators.any?
          filter_class.available_operators.first.label
        end
      end
      hide_select_box ? label1 + select_box + label : label1 + select_box
    end)
  end
  # rubocop:enable Metrics/AbcSize

  def hidden_for_sighted_label
    "#{h(filter_class.label)} #{I18n.t(:label_operator)} #{I18n.t('js.filter.description.text_open_filter')}"
  end
end
