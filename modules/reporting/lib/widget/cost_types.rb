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

class Widget::CostTypes < Widget::Base
  def render_with_options(options, &)
    @cost_types = options.delete(:cost_types)
    @selected_type_id = options.delete(:selected_type_id)

    super
  end

  def render
    write contents
  end

  def contents
    content_tag :div do
      tabs = available_cost_type_tabs(@subject).sort_by { |id, _| id }.map do |id, label|
        content_tag :div, class: "form--field -trailing-label" do
          types = label_tag "unit_#{id}", h(label), class: "form--label"
          types += content_tag :span, class: "form--field-container" do
            content_tag :span, class: "form--radio-button-container" do
              radio_button_tag("unit", id, id == @selected_type_id, class: "form--radio-button")
            end
          end
        end
      end

      safe_join(tabs)
    end
  end
end
