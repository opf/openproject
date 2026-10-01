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

module OpenProject
  module Common
    # @hidden
    class SubHeaderPreview < Lookbook::Preview
      def default
        render(Primer::OpenProject::SubHeader.new) do |component|
          component.with_filter_input(name: "filter", label: "Filter")
          component.with_filter_button do |button|
            button.with_trailing_visual_counter(count: "15")
            "All Filters"
          end
          component.with_action_button(
            leading_icon: :plus,
            label: "New item",
            scheme: :primary
          ) do
            "Create"
          end
        end
      end

      # @label Playground
      # @param show_filter_input toggle
      # @param show_filter_button toggle
      # @param show_action_button toggle
      # @param text text
      def playground(show_filter_input: true, show_filter_button: true, show_action_button: true, text: "Monday, 12th")
        render(Primer::OpenProject::SubHeader.new) do |component|
          component.with_filter_input(name: "filter", label: "Filter") if show_filter_input
          if show_filter_button
            component.with_filter_button do |button|
              button.with_trailing_visual_counter(count: "15")
              "All filters"
            end
          end

          component.with_text { text } unless text.nil?

          if show_action_button
            component.with_action_button(
              leading_icon: :plus,
              label: "New item",
              scheme: :primary
            ) do
              "Create"
            end
          end
        end
      end
    end
  end
end
