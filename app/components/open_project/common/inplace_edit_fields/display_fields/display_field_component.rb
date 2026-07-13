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
    module InplaceEditFields
      module DisplayFields
        class DisplayFieldComponent < ViewComponent::Base
          include OpPrimer::ComponentHelpers

          attr_reader :model, :attribute, :writable, :truncated

          def initialize(model:, attribute:, writable:, truncated:, has_comment: false, show_comment: false, **system_arguments)
            super()
            @model = model
            @attribute = attribute
            @writable = writable
            @truncated = truncated
            @has_comment = has_comment
            @show_comment = show_comment
            @system_arguments = system_arguments
          end

          def render_display_value
            value = model.public_send(attribute)

            if value.is_a?(TrueClass) || value.is_a?(FalseClass)
              boolean_display_value(value)
            elsif value.is_a?(Date) || value.is_a?(Time)
              helpers.format_date(value)
            elsif value.present? && value != [nil]
              format_present_value(value)
            else
              t("placeholders.default")
            end
          end

          def display_field_arguments
            @display_field_arguments ||= if open_in_dialog?
                                           base_arguments.merge(dialog_field_arguments)
                                         else
                                           base_arguments.merge(inline_edit_field_arguments)
                                         end
          end

          def open_in_dialog?
            @system_arguments[:dialog_controller_name].present?
          end

          def base_arguments
            {
              classes: display_field_classes,
              id: @system_arguments[:id],
              role: "button",
              tabindex: 0
            }
          end

          def dialog_field_arguments
            return {} unless writable? || @has_comment

            {
              data: {
                controller: "inplace-edit async-dialog",
                inplace_edit_dialog_url_value: @system_arguments[:dialog_url],
                action: dialog_controller_actions,
                test_selector: "inplace-edit-dialog-button-#{model.id}"
              },
              aria: {
                label: [
                  I18n.t(:label_edit_x, x: @system_arguments[:label]),
                  I18n.t(:label_value_x, x: render_display_value)
                ].join(", ")
              }
            }
          end

          def inline_edit_field_arguments
            return {} unless writable?

            {
              data: {
                controller: "inplace-edit",
                inplace_edit_url_value: edit_url,
                action: inline_controller_actions,
                test_selector: "inplace-edit-field-button-#{model.id}"
              }
            }
          end

          def render_calculation_error
            # no-op — subclasses may override to render a calculation error row
          end

          def show_comment?
            @show_comment
          end

          def input_specific_call
            render(Primer::BaseComponent.new(tag: :div, **display_field_arguments)) do
              render_display_value
            end
          end

          def render_tooltip
            nil
          end

          def custom_field?
            attribute.to_s.start_with?("custom_field_")
          end

          def custom_field
            return @custom_field if defined?(@custom_field)

            @custom_field = CustomField.find_by(id: attribute.to_s.sub("custom_field_", "").to_i)
          end

          private

          def display_field_classes
            # The later check catches non-editable users which should still see the comment in a dialog
            clickable = writable? || open_in_dialog?
            "op-inplace-edit--display-field#{' op-inplace-edit--display-field_clickable' if clickable}"
          end

          def format_present_value(value)
            if custom_field?
              helpers.format_value(value, custom_field)
            else
              value.to_s
            end
          end

          def comment_text
            model.custom_comment_for(custom_field)&.text.presence || t("placeholders.default")
          end

          def edit_url
            inplace_edit_field_edit_path(
              model: model.class.name,
              id: model.id,
              attribute:,
              system_arguments_json: @system_arguments.to_json
            )
          end

          def boolean_display_value(value)
            I18n.t("general_text_#{value ? 'Yes' : 'No'}")
          end

          def writable?
            writable && (@system_arguments[:readonly].nil? || @system_arguments[:readonly] == false)
          end

          def custom_field_values
            CustomValue
              .includes(custom_field: :custom_options)
              .where(
                custom_field_id: custom_field&.id,
                customized_id: model.id
              )
              .to_a
          end

          def dialog_controller_actions
            return "" unless writable? || @has_comment

            [
              "click->inplace-edit#openDialog",
              "keydown.enter->inplace-edit#openDialog",
              "keydown.space->inplace-edit#openDialog",
              "inplace-edit:open-dialog->async-dialog#handleOpenDialog"
            ].join(" ")
          end

          def inline_controller_actions
            return "" unless writable?

            [
              "click->inplace-edit#request",
              "keydown.enter->inplace-edit#request",
              "keydown.space->inplace-edit#request"
            ].join(" ")
          end
        end
      end
    end
  end
end
