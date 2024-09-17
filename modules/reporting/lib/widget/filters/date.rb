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

  def render # rubocop:disable Metrics/AbcSize
    @calendar_headers_tags_included = true

    name = "values[#{filter_class.underscore_name}][]"
    id_prefix = "#{filter_class.underscore_name}_"

    write(content_tag(:span, class: "advanced-filters--filter-value -binary") do
      label1 = label_tag "#{id_prefix}arg_1_val",
                         h(filter_class.label) + " " + I18n.t(:label_filter_value),
                         class: "hidden-for-sighted"

      arg1 = content_tag :span, id: "#{id_prefix}arg_1" do
        text1 = angular_component_tag "opce-basic-single-date-picker",
                                      inputs: {
                                        value: filter.values.first.to_s,
                                        id: "#{id_prefix}arg_1_val",
                                        name:
                                      }
        label1 + text1
      end

      label2 = label_tag "#{id_prefix}arg_2_val",
                         h(filter_class.label) + " " + I18n.t(:label_filter_value),
                         class: "hidden-for-sighted"

      arg2 = content_tag :span, id: "#{id_prefix}arg_2", class: "advanced-filters--filter-value2" do
        text2 = angular_component_tag "opce-basic-single-date-picker",
                                      inputs: {
                                        value: filter.values.second.to_s,
                                        id: "#{id_prefix}arg_2_val",
                                        name: name.to_s
                                      }
        label2 + text2
      end

      arg1 + arg2
    end)
  end
end
