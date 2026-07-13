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

class Widget::Filters::User < Widget::Filters::Base
  include AngularHelper

  def render # rubocop:disable Metrics/AbcSize
    write(content_tag(:div, id: "#{filter_class.underscore_name}_arg_1", class: "advanced-filters--filter-value") do
      label = html_label

      selected_values = map_filter_values

      box = angular_component_tag "opce-user-autocompleter",
                                  inputs: {
                                    appendTo: "body",
                                    InputName: "values[#{filter_class.underscore_name}]",
                                    hiddenFieldAction: "change->reporting--page#selectValueChanged",
                                    multiple: true,
                                    model: selected_values.compact,
                                    resource: "principals",
                                    url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
                                    filters: [
                                      { name: "type", operator: "=", values: ["User"] }
                                    ],
                                    additionalOptions: [
                                      { id: CostQuery::Filter::UserId.me_value, name: I18n.t(:label_me) }
                                    ]
                                  },
                                  id: "#{filter_class.underscore_name}_select_1",
                                  class: "filter-value"

      content_tag(:span, class: "inline-label") do
        label + box
      end
    end)
  end

  private

  def html_label
    label_tag "#{filter_class.underscore_name}_arg_1_val",
              "#{h(filter_class.label)} #{I18n.t(:label_filter_value)}",
              class: "sr-only"
  end

  def map_filter_values
    expand_comma_separated_values!

    users = User.visible.where(id: filter.values).index_by(&:id)

    filter.values.filter_map do |id|
      if id == CostQuery::Filter::UserId.me_value
        { id: CostQuery::Filter::UserId.me_value, name: I18n.t(:label_me) }
      elsif (user = users[id.to_i])
        { id: id, name: user.name }
      end
    end
  end
end
