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
  module ProjectCustomFieldSections
    class ShowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(project_custom_field_section:, first_and_last: [])
        super

        @project_custom_field_section = project_custom_field_section
        @ordered_cfs = project_custom_field_section.custom_fields_in_order

        @first_and_last = first_and_last
      end

      def custom_field_row_component_class
        Settings::ProjectCustomFieldSections::CustomFieldRowComponent
      end

      private

      def wrapper_uniq_by
        @project_custom_field_section.id
      end

      def drag_and_drop_target_config
        {
          generic_drag_and_drop_target: "container",
          "target-container-accessor": ".Box > ul",
          "target-id": @project_custom_field_section.id,
          "target-allowed-drag-type": "custom-field"
        }
      end

      def draggable_item_config(project_custom_field)
        {
          "draggable-id": project_custom_field.id,
          "draggable-type": "custom-field",
          "drop-url": drop_admin_settings_project_custom_field_path(project_custom_field)
        }
      end

      def move_actions(menu)
        unless first?
          move_action_item(menu, :highest, t("label_agenda_item_move_to_top"),
                           "move-to-top")
          move_action_item(menu, :higher, t("label_agenda_item_move_up"), "chevron-up")
        end
        unless last?
          move_action_item(menu, :lower, t("label_agenda_item_move_down"),
                           "chevron-down")
          move_action_item(menu, :lowest, t("label_agenda_item_move_to_bottom"),
                           "move-to-bottom")
        end
      end

      def move_action_item(menu, move_to, label_text, icon)
        menu.with_item(label: label_text,
                       href: move_admin_settings_project_custom_field_section_path(@project_custom_field_section, move_to:),
                       form_arguments: {
                         method: :put, data: { "turbo-stream": true,
                                               test_selector: "project-custom-field-section-move-#{move_to}" }
                       }) do |item|
          item.with_leading_visual_icon(icon:)
        end
      end

      def disabled_delete_action_item(menu)
        menu.with_item(label: t("text_destroy"),
                       disabled: true) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def edit_action_item(menu)
        menu.with_item(label: t("settings.project_attributes.label_edit_section"),
                       tag: :button,
                       content_arguments: {
                         "data-show-dialog-id": "project-custom-field-section-dialog#{@project_custom_field_section.id}",
                         "data-test-selector": "project-custom-field-section-edit"
                       },
                       value: "") do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def delete_action_item(menu)
        menu.with_item(label: t("text_destroy"),
                       scheme: :danger,
                       href: admin_settings_project_custom_field_section_path(@project_custom_field_section),
                       form_arguments: {
                         method: :delete,
                         data: {
                           turbo_confirm: t(:text_are_you_sure),
                           turbo_stream: true,
                           test_selector: "project-custom-field-section-delete"
                         }
                       }) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def first?
        return @first unless @first.nil?

        @first = if @first_and_last.first
                   @first_and_last.first == @project_custom_field_section
                 else
                   @project_custom_field_section.first?
                 end
      end

      def last?
        return @last unless @last.nil?

        @last = if @first_and_last.last
                  @first_and_last.last == @project_custom_field_section
                else
                  @project_custom_field_section.last?
                end
      end

      def action_menu_item_for_custom_field_format(menu, format)
        menu.with_item(
          label: helpers.label_for_custom_field_format(format.name),
          tag: :a,
          href: new_admin_settings_project_custom_field_path(
            field_format: format.name,
            custom_field_section_id: @project_custom_field_section.id
          ),
          content_arguments: { data: { turbo: "false",
                                       test_selector: "new-project-custom-field-in-section-button-#{format.name}" } }
        )
      end

      def display_representation_icon_for_section(section)
        section.shown_in_overview_sidebar? ? :"op-view-split" : :"op-view-cards"
      end

      def display_representation_label_for_section(section)
        if section.shown_in_overview_sidebar?
          t("settings.project_attributes.sections.display_representation.overview.side_panel.label")
        else
          t("settings.project_attributes.sections.display_representation.overview.main_area.label")
        end
      end

      def menu_item_options_for(section, key)
        {
          href: admin_settings_project_custom_field_section_path(section),
          form_arguments: {
            method: :put,
            inputs: [{
              name: "project_custom_field_section[overview]",
              value: key
            }]
          }
        }
      end
    end
  end
end
