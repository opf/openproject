#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Settings
  module ProjectAttributes
    module Section
      class ProjectCustomFieldComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(project_custom_field:)
          super

          @project_custom_field = project_custom_field
        end

        private

        def edit_action_item(menu)
          menu.with_item(label: t("label_edit"),
                         href: edit_custom_field_path(@project_custom_field)) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end
        end

        def move_actions(menu)
          move_action_item(menu, :highest, t("label_agenda_item_move_to_top"), "move-to-top") unless @project_custom_field.first?
          move_action_item(menu, :higher, t("label_agenda_item_move_up"), "chevron-up") unless @project_custom_field.first?
          move_action_item(menu, :lower, t("label_agenda_item_move_down"), "chevron-down") unless @project_custom_field.last?
          unless @project_custom_field.last?
            move_action_item(menu, :lowest, t("label_agenda_item_move_to_bottom"),
                             "move-to-bottom")
          end
        end

        def move_action_item(menu, move_to, label_text, icon)
          menu.with_item(label: label_text,
                         href: move_admin_settings_project_custom_field_path(@project_custom_field, move_to:),
                         form_arguments: {
                           method: :put, data: { 'turbo-stream': true }
                         }) do |item|
            item.with_leading_visual_icon(icon:)
          end
        end

        # def delete_action_item(menu)
        #   menu.with_item(label: t("text_destroy"),
        #                  scheme: :danger,
        #                  href: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
        #                  form_arguments: {
        #                    method: :delete, data: { confirm: t("text_are_you_sure"), 'turbo-stream': true }
        #                  }) do |item|
        #     item.with_leading_visual_icon(icon: :trash)
        #   end
        # end
      end
    end
  end
end
