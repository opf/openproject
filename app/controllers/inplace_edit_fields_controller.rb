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

class InplaceEditFieldsController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :find_model
  before_action :set_attribute
  before_action :authorize_project_custom_field_visibility!, if: :custom_field_attribute?
  no_authorization_required! :edit, :update, :reset, :dialog

  def edit
    replace_via_turbo_stream(
      component: component(enforce_edit_mode: true),
      status: :ok
    )

    respond_with_turbo_streams
  end

  def update
    success = invoke_update_handler
    handle_update_success if success
    replace_field_component(success)
    respond_with_turbo_streams
  rescue ArgumentError
    head :not_found
  end

  def reset
    replace_via_turbo_stream(component:)
    respond_with_turbo_streams
  end

  def dialog
    respond_with_dialog(
      OpenProject::Common::InplaceEditFieldDialogComponent.new(
        model: @model,
        attribute: @attribute,
        system_arguments: system_arguments.to_h.symbolize_keys
      )
    )
  end

  private

  def invoke_update_handler
    handler = update_registry.fetch_handler(@model)
    raise ArgumentError, "Missing update handler for #{@model}" if handler.blank?

    handler.call(model: @model, params: permitted_params, user: current_user)
  end

  def handle_update_success
    render_success_flash_message_via_turbo_stream(
      message: I18n.t(:notice_successful_update)
    )
    close_dialog_via_turbo_stream(dialog_id) if dialog_id
    refresh_calculated_dependents
  end

  def replace_field_component(success)
    if !success && dialog_id
      replace_via_turbo_stream(
        component: dialog_field_component,
        status: :unprocessable_entity
      )
    else
      replace_via_turbo_stream(
        component: component(enforce_edit_mode: !success),
        status: success ? :ok : :unprocessable_entity
      )
    end
  end

  def find_model
    model_class = resolve_model_class(params[:model])
    @model = model_class.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound, ArgumentError
    head :not_found
  end

  def resolve_model_class(model_param)
    return nil if model_param.blank?

    model_class =
      update_registry.resolve_model_class(model_param)

    unless model_class &&
           model_class < ApplicationRecord &&
           model_class.respond_to?(:visible)
      raise ArgumentError, "Unsupported model for inplace edit"
    end

    model_class
  end

  def set_attribute
    @attribute = params[:attribute].to_sym
  end

  def authorize_project_custom_field_visibility!
    return unless @model.is_a?(Project)

    custom_field_id = @attribute.to_s.delete_prefix("custom_field_").to_i
    unless ProjectCustomField.visible(current_user, project: @model).exists?(custom_field_id)
      head :not_found
    end
  end

  def permitted_params
    if custom_field_via_fields_for?
      transform_custom_field_values_params.merge(custom_comments_params)
    else
      params.expect(@model.model_name.param_key => [@attribute]).merge(custom_comments_params)
    end
  end

  def custom_field_attribute?
    @attribute.to_s.start_with?("custom_field_")
  end

  def custom_field_via_fields_for?
    custom_field_attribute? &&
      params[@model.model_name.param_key]&.key?(:custom_field_values)
  end

  def custom_comments_params
    return {} unless custom_field_attribute?

    custom_field_id = @attribute.to_s.delete_prefix("custom_field_")
    raw_comment = params.dig(@model.model_name.param_key, :custom_comments, custom_field_id)

    return {} if raw_comment.nil?

    { custom_comments: { custom_field_id => raw_comment } }
  end

  def transform_custom_field_values_params
    model_key = @model.model_name.param_key
    custom_field_id = @attribute.to_s.delete_prefix("custom_field_")

    # Strong Parameters doesn't support dynamic keys in nested hashes
    # So we extract the value directly from the raw params.
    # Two formats are supported:
    #   - Array format: project[custom_field_values][] (used by FilterableTreeView / hierarchy fields)
    #   - Hash format:  project[custom_field_values][{id}] (used by SelectList / legacy fields_for)
    cf_values = params.dig(model_key, :custom_field_values)
    raw_value = cf_values.is_a?(Array) ? cf_values : cf_values&.dig(custom_field_id)

    { @attribute => process_cf_raw_value(raw_value, custom_field_id) }
  end

  def process_cf_raw_value(raw_value, custom_field_id)
    return raw_value unless raw_value.is_a?(Array)

    cleaned_values = raw_value.compact_blank
    # FilterableTreeView encodes each selected item as a JSON payload
    # {"path":[...],"value":"<id>"} — extract only the "value" field.
    # Only hierarchy-format fields use this encoding, so we check the field format first.
    values = if hierarchy_format_custom_field?(custom_field_id)
               cleaned_values.map { |v| JSON.parse(v)["value"] }
             else
               cleaned_values
             end
    # For single-select, unwrap the array to get the single value
    values.size <= 1 ? values.first : values
  end

  def hierarchy_format_custom_field?(custom_field_id)
    @model.available_custom_fields.exists?(id: custom_field_id, field_format: %w[hierarchy weighted_item_list])
  end

  def component(enforce_edit_mode: false)
    args = system_arguments.to_h.symbolize_keys

    # When saving from a dialog, restore the page component's id so the Turbo
    # Stream replacement targets the correct wrapper on the page. Also strip
    # dialog-specific arguments that must not bleed into the display component.
    args[:id] = args.delete(:page_component_id) if args[:page_component_id]
    args = args.except(:wrapper_id, :form_id)

    OpenProject::Common::InplaceEditFieldComponent.new(
      model: @model,
      attribute: @attribute,
      enforce_edit_mode:,
      update_registry:,
      **args
    )
  end

  # Builds the edit-mode component targeting the field *inside* the dialog.
  # Used when an update fails while submitting from a dialog: the error state
  # should be shown within the dialog, not at the page trigger location.
  # Keeps the dialog field's own :id (not page_component_id) so the Turbo
  # Stream targets the correct wrapper inside the dialog, and preserves
  # :wrapper_id / :form_id so the re-rendered form still submits via the dialog.
  def dialog_field_component
    args = system_arguments.to_h.symbolize_keys

    OpenProject::Common::InplaceEditFieldComponent.new(
      model: @model,
      attribute: @attribute,
      enforce_edit_mode: true,
      show_action_buttons: false,
      update_registry:,
      **args
    )
  end

  def dialog_id
    wrapper_id = system_arguments.to_h["wrapper_id"]
    wrapper_id&.delete_prefix("#")
  end

  def refresh_calculated_dependents
    return unless custom_field_attribute?
    return unless @model.respond_to?(:available_custom_fields)

    affected = affected_calculated_fields
    return if affected.empty?

    affected.each { |custom_field| turbo_streams << calculated_field_turbo_stream(custom_field) }
  end

  def affected_calculated_fields
    cf_id = @attribute.to_s.delete_prefix("custom_field_").to_i
    @model.available_custom_fields.affected_calculated_fields([cf_id])
  end

  def calculated_field_turbo_stream(custom_field)
    attribute = custom_field.attribute_name.to_sym
    stable_key = "#{@model.class.name.parameterize(separator: '_')}_#{@model.id}_#{attribute}"

    # Use the field's own system_arguments sent by the client from the DOM data attribute.
    # Fall back to an empty hash if not present (e.g. in tests or non-JS contexts).
    field_args = stable_key_system_arguments
                   .fetch(stable_key, {})
                   .symbolize_keys
                   .except(:id) # exclude UUID so the component generates a fresh one

    comp = OpenProject::Common::InplaceEditFieldComponent.new(
      model: @model,
      attribute:,
      update_registry:,
      **field_args
    )
    comp.render_as_turbo_stream(
      view_context:,
      action: :replace,
      target: nil,
      targets: "[data-inplace-edit-stable-key='#{stable_key}']"
    )
  end

  def stable_key_system_arguments
    @stable_key_system_arguments ||= parse_stable_key_system_arguments
  end

  def parse_stable_key_system_arguments
    raw = params[:stable_key_system_arguments]
    return {} if raw.blank?

    JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end

  def update_registry
    @update_registry ||= OpenProject::InplaceEdit::UpdateRegistry.default
  end

  def system_arguments
    arguments = params[:system_arguments_json].presence || params.to_unsafe_h
                                    .values
                                    .filter_map { |v| v["system_arguments_json"] }
                                    .first

    arguments.nil? ? {} : JSON.parse(arguments)
  end
end
