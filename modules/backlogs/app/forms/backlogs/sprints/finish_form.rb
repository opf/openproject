# frozen_string_literal: true

# -- copyright
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
# ++

module Backlogs
  module Sprints
    class FinishForm < ApplicationForm
      extend Dry::Initializer

      option :available_sprints
      option :message

      form do |form|
        form.html_content do
          render(Primer::Beta::Text.new) { message }
        end
        form.radio_button_group(name: "unfinished_action") do |group|
          # Option 1: Move to top of backlog
          group.radio_button(
            label: label("actions.move_to_top_of_backlog"),
            value: :move_to_top_of_backlog,
            checked: !sprints_available?,
            data: {
              "show-when-value-selected-target": "cause",
              target_name: "unfinished_action"
            }
          )

          # Option 2: Move to bottom of backlog
          group.radio_button(
            label: label("actions.move_to_bottom_of_backlog"),
            value: :move_to_bottom_of_backlog,
            checked: !sprints_available?,
            data: {
              "show-when-value-selected-target": "cause",
              target_name: "unfinished_action"
            }
          )

          # Option 3: Move to another sprint (pre-selected)
          group.radio_button(
            label: label("actions.move_to_sprint"),
            value: :move_to_sprint,
            checked: sprints_available?,
            disabled: !sprints_available?,
            data: {
              "show-when-value-selected-target": "cause",
              target_name: "unfinished_action"
            }
          )
        end

        # Sprint select — visible by default since "move_to_sprint" is pre-selected
        form.group(ml: 4,
                   mt: -3,
                   data: {
                     "show-when-value-selected-target": "effect",
                     target_name: "unfinished_action",
                     value: "move_to_sprint",
                     set_visibility: "true"
                   },
                   style: "visibility: #{sprints_available? ? 'visible' : 'hidden'};") do |group|
          group.select_list(name: :move_to_sprint_id,
                            input_width: :medium,
                            label: label("select_sprint_label")) do |select|
            available_sprints.each do |s|
              select.option(label: s.name, value: s.id)
            end
          end
        end
      end

      private

      def sprints_available?
        available_sprints.any?
      end

      def label(key)
        helpers.t("backlogs.finish_sprint_dialog_component.#{key}")
      end
    end
  end
end
