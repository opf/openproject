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

module AI
  module TextTransformActions
    class Form < ApplicationForm
      SCOPE_TARGET_NAME = "usage_scope"
      TYPES_PANEL_ID = "ai-text-transform-action-types"

      form do |f|
        f.text_field(
          name: :label,
          label: attribute_name(:label),
          required: true,
          caption: I18n.t("admin.text_transform_actions.form.label_caption"),
          input_width: :large
        )

        f.text_area(
          name: :prompt,
          label: attribute_name(:prompt),
          required: true,
          rows: 8
        )

        f.select_list(
          name: :usage_scope,
          label: attribute_name(:usage_scope),
          caption: I18n.t("admin.text_transform_actions.form.usage_scope_caption"),
          input_width: :large,
          include_blank: false,
          data: {
            show_when_value_selected_target: "cause",
            target_name: SCOPE_TARGET_NAME
          }
        ) do |select|
          AI::TextTransformAction.usage_scopes.each_key do |scope|
            select.option(
              value: scope,
              label: I18n.t("admin.text_transform_actions.usage_scopes.#{scope}")
            )
          end
        end

        f.group(
          hidden: !model.specific_work_package_types?,
          data: {
            show_when_value_selected_target: "effect",
            target_name: SCOPE_TARGET_NAME,
            value: "specific_work_package_types",
            test_selector: "text-transform-action-types-group"
          }
        ) do |group|
          # Ensures an empty selection still submits type_ids, as the select
          # panel renders no input at all once every item is unchecked.
          group.hidden(
            name: "ai_text_transform_action[type_ids][]",
            value: "",
            scope_name_to_model: false
          )

          group.html_content { types_form_control }
        end

        f.group(
          hidden: model.everywhere?,
          data: {
            show_when_value_selected_target: "effect",
            target_name: SCOPE_TARGET_NAME,
            not_value: "everywhere",
            test_selector: "text-transform-action-template-group"
          }
        ) do |group|
          group.check_box(
            name: :injects_type_template,
            label: attribute_name(:injects_type_template),
            caption: I18n.t("admin.text_transform_actions.form.injects_type_template_caption")
          )
        end

        f.submit(
          name: :submit,
          label: model.persisted? ? I18n.t(:button_save) : I18n.t(:button_create),
          scheme: :primary
        )
      end

      private

      def types_form_control
        render(
          Primer::Alpha::FormControl.new(
            label: attribute_name(:types),
            caption: I18n.t("admin.text_transform_actions.form.types_caption"),
            validation_message: model.errors.full_messages_for(:types).first,
            required: true,
            label_arguments: { for: "#{TYPES_PANEL_ID}-button" }
          )
        ) do |control|
          control.with_input { |input_arguments| types_select_panel(input_arguments) }
        end
      end

      def types_select_panel(input_arguments)
        selected_type_ids = model.type_ids

        render(
          Primer::Alpha::SelectPanel.new(
            id: TYPES_PANEL_ID,
            select_variant: :multiple,
            fetch_strategy: :local,
            title: I18n.t("admin.text_transform_actions.form.select_types"),
            dynamic_label: true,
            form_arguments: { builder: @builder, name: :type_ids },
            data: { test_selector: "text-transform-action-types-panel" }
          )
        ) do |panel|
          types_show_button(panel, input_arguments)
          types_items(panel, selected_type_ids)
        end
      end

      def types_show_button(panel, input_arguments)
        panel.with_show_button(
          scheme: :secondary,
          aria: { describedby: input_arguments.dig(:aria, :describedby) },
          test_selector: "text-transform-action-select-types"
        ) do |button|
          button.with_trailing_action_icon(icon: :"triangle-down")
          I18n.t("admin.text_transform_actions.form.select_types")
        end
      end

      def types_items(panel, selected_type_ids)
        Type.order(:position, :id).each do |type|
          panel.with_item(
            label: type.name,
            active: selected_type_ids.include?(type.id),
            item_id: type.id,
            content_arguments: { data: { value: type.id } }
          )
        end
      end
    end
  end
end
