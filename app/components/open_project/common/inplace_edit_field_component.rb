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
    class InplaceEditFieldComponent < ViewComponent::Base
      include OpTurbo::Streamable

      attr_reader :model, :attribute, :enforce_edit_mode, :open_in_dialog, :show_action_buttons, :truncated

      def initialize(model:,
                     attribute:,
                     enforce_edit_mode: false,
                     open_in_dialog: false,
                     show_action_buttons: true,
                     truncated: false,
                     update_registry: OpenProject::InplaceEdit::UpdateRegistry.default,
                     **system_arguments)
        super()
        @model = model
        @attribute = attribute
        @enforce_edit_mode = enforce_edit_mode
        @open_in_dialog = open_in_dialog
        @show_action_buttons = show_action_buttons
        @truncated = truncated
        @update_registry = update_registry
        @system_arguments = system_arguments

        @system_arguments[:id] = system_arguments[:id] || SecureRandom.uuid
        @system_arguments[:required] ||= required?
        @system_arguments[:label] ||= field_label
        @system_arguments[:truncated] = truncated
      end

      def field_class
        if custom_field?
          OpenProject::InplaceEdit::FieldRegistry.fetch_for_custom_field_format(custom_field&.field_format)
        else
          OpenProject::InplaceEdit::FieldRegistry.fetch(attribute)
        end
      end

      def edit_field_component(form)
        field_class.new(
          form:,
          attribute:,
          model:,
          show_action_buttons:,
          **@system_arguments
        )
      end

      def display_field_class
        if field_class.respond_to?(:display_class)
          field_class.display_class
        else
          InplaceEditFields::DisplayFields::DisplayFieldComponent
        end
      end

      def display_field_component
        return nil if display_field_class.nil?

        @display_field_component ||= build_display_field_component
      end

      def wrapper_key
        "op-inplace-edit-field--#{model_class}-#{model.id}--#{attribute.name}--#{@system_arguments[:id]}"
      end

      def wrapper_test_selector
        "op-inplace-edit-field--#{model_class}-#{model.id}--#{attribute.name}"
      end

      def wrapper_uniq_by
        "#{model_class}_#{@model.id}_#{@attribute}"
      end

      def form_id
        @system_arguments[:form_id]
      end

      def wrapper_id
        @system_arguments[:wrapper_id]
      end

      def form_options
        options = {
          model: @model,
          url: inplace_edit_field_update_path(
            model: @model.class.name,
            id: @model.id,
            attribute: @attribute
          ),
          method: :patch,
          data: { turbo_stream: true,
                  test_selector: "op-inplace-edit-field--form" }

        }

        options[:id] = form_id if form_id.present?
        options
      end

      def open_in_dialog?
        @open_in_dialog || field_class.open_in_dialog? || (custom_field? && custom_field&.has_comment?)
      end

      def dialog_edit_url
        return unless open_in_dialog?

        inplace_edit_field_dialog_path(
          model: model.class.name,
          id: model.id,
          attribute:,
          system_arguments_json: @system_arguments
            .except(:id)
            .merge(page_component_id: @system_arguments[:id], writable: writable?)
            .to_json
        )
      end

      def model_class
        @model_class ||= @model.class.name.parameterize(separator: "_")
      end

      private

      def build_display_field_component
        has_comment = custom_field? && custom_field&.has_comment?
        additional_args = open_in_dialog? ? dialog_display_arguments : {}
        display_field_class.new(
          model:,
          attribute:,
          writable: writable?,
          truncated:,
          has_comment:,
          # Show comment as read-only text when a non-writable user opens the dialog.
          # enforce_edit_mode identifies the dialog context.
          show_comment: enforce_edit_mode && !writable? && has_comment,
          **@system_arguments.merge(additional_args)
        )
      end

      def dialog_trigger_arguments
        {
          dialog_controller_name: "inplace-edit",
          dialog_url: dialog_edit_url
        }
      end

      # When inside a dialog and the field is not writable, strip dialog trigger args
      # to prevent opening a nested dialog from the display component.
      def dialog_display_arguments
        return {} if enforce_edit_mode && !writable?

        dialog_trigger_arguments
      end

      def writable?
        return @writable if defined?(@writable)

        contract_class = @update_registry.fetch_contract(model)
        @writable =
          if contract_class.present?
            contract_class.new(model, User.current).writable?(attribute)
          else
            false
          end
      end

      def field_label
        # Check if this is a custom field attribute
        if custom_field? && custom_field
          return custom_field.name
        end

        label = model.class.human_attribute_name(attribute)
        label = label.titleize if attribute.to_s.include?("_")
        label
      end

      def required?
        return @required if instance_variable_defined?(:@required)

        @required = if @system_arguments.key?(:required)
                      @system_arguments[:required]
                    elsif custom_field?
                      # For custom fields, check the is_required attribute
                      custom_field&.is_required || false
                    else
                      false
                    end
      end

      def custom_field?
        attribute.to_s.start_with?("custom_field_")
      end

      def custom_field
        return @custom_field if defined?(@custom_field)

        @custom_field = CustomField.find_by(id: attribute.to_s.sub("custom_field_", "").to_i)
      end
    end
  end
end
