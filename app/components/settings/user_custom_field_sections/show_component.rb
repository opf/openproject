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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Settings
  module UserCustomFieldSections
    class ShowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable
      include SortableLists::MoveMenu

      def initialize(user_custom_field_section:, sections:)
        super

        @user_custom_field_section = user_custom_field_section
        @ordered_attributes = user_custom_field_section.attribute_order
        @custom_fields_by_key = user_custom_field_section.custom_fields_by_key

        @other_sections = sections.reject { |section| section.id == user_custom_field_section.id }
      end

      def custom_field_row_component_class
        Settings::UserCustomFieldSections::CustomFieldRowComponent
      end

      private

      def available_formats
        OpenProject::CustomFieldFormat.available_for_class_name("User").sort_by(&:name)
      end

      def wrapper_uniq_by
        @user_custom_field_section.id
      end

      def field_list_data
        {
          controller: "sortable-lists--list",
          sortable_lists__list_type_value: "user_field",
          sortable_lists__list_accepted_type_value: "user_field",
          sortable_lists__list_id_value: @user_custom_field_section.id,
          sortable_lists__list_name_value: @user_custom_field_section.name,
          # To omit the box's top margin and square off any rounded corners.
          sortable_lists__item_target: "preview"
        }
      end

      def field_item_data_for_built_in(key)
        {
          controller: "sortable-lists--item",
          sortable_lists__item_id_value: key,
          sortable_lists__item_type_value: "user_field",
          sortable_lists__item_label_value: User.human_attribute_name(key)
        }
      end

      def field_item_data_for_custom_field(cf)
        {
          controller: "sortable-lists--item",
          sortable_lists__item_id_value: cf.id,
          sortable_lists__item_type_value: "user_field",
          sortable_lists__item_label_value: cf.name
        }
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
