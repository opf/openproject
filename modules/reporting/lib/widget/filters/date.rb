# frozen_string_literal: true

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

class Widget::Filters::Date < Widget::Filters::Base
  include AngularHelper

  def render_filter # rubocop:disable Metrics/AbcSize
    name = "values[#{filter_class.underscore_name}][]"
    id_prefix = "#{filter_class.underscore_name}_"

    content_tag(:span, class: "advanced-filters--filter-value -binary") do
      label1 = label_tag "#{id_prefix}arg_1_val",
                         value_label,
                         class: "sr-only"

      arg1 = content_tag :span, id: "#{id_prefix}arg_1" do
        text1 = angular_component_tag "opce-basic-single-date-picker",
                                      inputs: {
                                        value: filter.operator.forced == :integers ? "" : filter.values.first.to_s,
                                        id: "#{id_prefix}arg_1_val",
                                        name:
                                      }
        label1 + text1
      end

      label2 = label_tag "#{id_prefix}arg_2_val",
                         value_label,
                         class: "sr-only"

      arg2 = content_tag :span, id: "#{id_prefix}arg_2", class: "advanced-filters--filter-value2" do
        text2 = angular_component_tag "opce-basic-single-date-picker",
                                      inputs: {
                                        value: filter.operator.forced == :integers ? "" : filter.values.second.to_s,
                                        id: "#{id_prefix}arg_2_val",
                                        name: name.to_s
                                      }
        label2 + text2
      end

      arg3 = content_tag :span, id: "#{id_prefix}arg_1_integers", class: "advanced-filters--integer" do
        label3 = label_tag "#{id_prefix}arg_1_integers_val",
                           value_label,
                           class: "sr-only"

        label3 + text_field_tag(name,
                                filter.operator.forced == :integers ? filter.values.first.to_s : "",
                                type: "number",
                                min: 0,
                                steps: 1,
                                class: "advanced-filters--text-field -slim",
                                id: "#{id_prefix}arg_1_integers_val",
                                "data-filter-name": filter_class.underscore_name)
      end

      arg1 + arg2 + arg3
    end
  end

  def value_label
    "#{filter_class.label} #{I18n.t(:label_filter_value)}"
  end
end
