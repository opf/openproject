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

module Settings
  module UserCustomFieldSections
    class ShowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(user_custom_field_section:, first_and_last: [])
        super

        @user_custom_field_section = user_custom_field_section
        @ordered_attributes = user_custom_field_section.attribute_order
        @custom_fields_by_key = user_custom_field_section.custom_fields_by_key

        @first_and_last = first_and_last
      end

      def custom_field_row_component_class
        Settings::UserCustomFieldSections::CustomFieldRowComponent
      end

      private

      def wrapper_uniq_by
        @user_custom_field_section.id
      end

      def drag_and_drop_target_config
        {
          generic_drag_and_drop_target: "container",
          "target-container-accessor": ".Box > ul",
          "target-id": @user_custom_field_section.id,
          "target-allowed-drag-type": "user-field"
        }
      end

      def draggable_item_config_for_custom_field(user_custom_field)
        {
          "draggable-id": user_custom_field.id,
          "draggable-type": "user-field",
          "drop-url": drop_admin_settings_user_custom_field_path(user_custom_field)
        }
      end

      def draggable_item_config_for_built_in(key)
        {
          "draggable-id": key,
          "draggable-type": "user-field",
          "drop-url": drop_admin_settings_user_custom_field_section_built_in_attribute_path(
            @user_custom_field_section, key
          )
        }
      end

      def move_actions(menu)
        unless first?
          move_action_item(menu, :highest, t("label_agenda_item_move_to_top"), "move-to-top")
          move_action_item(menu, :higher, t("label_agenda_item_move_up"), "chevron-up")
        end
        unless last?
          move_action_item(menu, :lower, t("label_agenda_item_move_down"), "chevron-down")
          move_action_item(menu, :lowest, t("label_agenda_item_move_to_bottom"), "move-to-bottom")
        end
      end

      def move_action_item(menu, move_to, label_text, icon)
        menu.with_item(label: label_text,
                       href: move_admin_settings_user_custom_field_section_path(@user_custom_field_section, move_to:),
                       form_arguments: {
                         method: :put, data: { "turbo-stream": true,
                                               test_selector: "user-custom-field-section-move-#{move_to}" }
                       }) do |item|
          item.with_leading_visual_icon(icon:)
        end
      end

      def disabled_delete_action_item(menu)
        menu.with_item(label: t("text_destroy"), disabled: true) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def edit_action_item(menu)
        menu.with_item(label: t(".label_edit_section"),
                       tag: :button,
                       content_arguments: {
                         "data-show-dialog-id": "user-custom-field-section-dialog#{@user_custom_field_section.id}",
                         "data-test-selector": "user-custom-field-section-edit"
                       },
                       value: "") do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def delete_action_item(menu)
        menu.with_item(label: t("text_destroy"),
                       scheme: :danger,
                       href: admin_settings_user_custom_field_section_path(@user_custom_field_section),
                       form_arguments: {
                         method: :delete,
                         data: {
                           turbo_confirm: t(:text_are_you_sure),
                           turbo_stream: true,
                           test_selector: "user-custom-field-section-delete"
                         }
                       }) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def first?
        @first ||=
          if @first_and_last.first
            @first_and_last.first == @user_custom_field_section
          else
            @user_custom_field_section.first?
          end
      end

      def last?
        @last ||=
          if @first_and_last.last
            @first_and_last.last == @user_custom_field_section
          else
            @user_custom_field_section.last?
          end
      end

      def action_menu_item_for_custom_field_format(menu, format)
        menu.with_item(
          label: helpers.label_for_custom_field_format(format.name),
          tag: :a,
          href: new_admin_settings_user_custom_field_path(
            field_format: format.name,
            custom_field_section_id: @user_custom_field_section.id
          ),
          content_arguments: { data: { turbo: "false",
                                       test_selector: "new-user-custom-field-in-section-button-#{format.name}" } }
        )
      end
    end
  end
end
