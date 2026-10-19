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

module WorkPackageTypes
  class PdfExportTemplateController < ApplicationController
    include AddressesVariant
    include ::WorkPackageTypes::ConfiguredInScope
    include ::WorkPackageTypes::VariantRoutes
    include OpTurbo::ComponentStream

    before_action :find_type,
                  only: %i[edit toggle move enable_all disable_all update_artefact_export edit_settings
                           update_settings]
    before_action :find_variant,
                  only: %i[edit toggle move enable_all disable_all update_artefact_export edit_settings
                           update_settings]
    before_action :find_template, only: %i[toggle move edit_settings update_settings]

    rescue_from Type::PdfExportTemplates::ReadonlyError, with: :render_readonly_error

    current_menu_item do
      :types
    end

    def edit; end

    def edit_settings
      return head :not_found if @template.nil?

      @settings = @variant.pdf_export_templates.settings_for(@template.id)
      @readonly = @variant.pdf_export_templates.readonly?
    end

    def update_settings
      return head :not_found if @template.nil?

      if params[:commit] == "reset"
        reset_settings!
      else
        save_settings!
      end

      redirect_to edit_variant_pdf_export_template_index_path(variant_scope_project, @variant),
                  notice: I18n.t(:notice_successful_update)
    end

    def update_artefact_export
      mode = params.dig(@variant.model_name.param_key.to_sym, :artefact_export_mode)
      unless Type::ArtefactExport::MODES.include?(mode)
        render_error_flash_message_via_turbo_stream(
          message: I18n.t("types.edit.export_configuration.artefact_export.invalid_mode")
        )
        return respond_with_turbo_streams(status: :unprocessable_entity)
      end

      @variant.artefact_export_mode = mode
      @variant.save!
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
      respond_with_turbo_streams
    end

    def enable_all
      return render_404_turbo_stream if @type.nil?

      @variant.pdf_export_templates.enable_all
      @variant.save!
      respond_section_with_turbo_streams
    end

    def disable_all
      return render_404_turbo_stream if @type.nil?

      @variant.pdf_export_templates.disable_all
      @variant.save!
      respond_section_with_turbo_streams
    end

    def toggle
      return render_404_turbo_stream if @template.nil?

      @variant.pdf_export_templates.toggle(@template.id)
      @variant.save!
      respond_with_turbo_streams
    end

    def move
      return render_404_turbo_stream if @template.nil?

      moved = move_after_anchor

      if moved
        update_template_list_via_turbo_stream
        render_success_flash_message_via_turbo_stream(
          message: I18n.t(:"types.edit.export_configuration.pdf_export_templates.order_changed")
        )
      else
        render_error_flash_message_via_turbo_stream(message: I18n.t(:error_invalid_list_move_anchor))
      end

      respond_with_turbo_streams(status: moved ? :ok : :unprocessable_entity)
    end

    protected

    def permitted_settings
      params.permit(*@template.settings_component.fields).to_h
    end

    def save_settings!
      configured, blank = permitted_settings.partition { |_field, value| value.present? }.map(&:to_h)
      @variant.pdf_export_templates.update_settings(@template.id, configured)
      blank.each_key { |field| @variant.pdf_export_templates.clear_setting(@template.id, field) }
      @variant.save!
    end

    def reset_settings!
      @template.settings_component.fields.each do |field|
        @variant.pdf_export_templates.clear_setting(@template.id, field)
      end
      @variant.save!
    end

    def respond_section_with_turbo_streams
      update_template_list_via_turbo_stream
      respond_to_with_turbo_streams
    end

    def update_template_list_via_turbo_stream
      replace_via_turbo_stream(
        component: ::WorkPackageTypes::ExportTemplateListComponent.new(variant: @variant),
        method: "morph"
      )
    end

    def move_after_anchor
      return false unless valid_drop_request?

      moved = @variant.pdf_export_templates.move_after_anchor(@template.id, drop_params[:prev_id])
      @variant.save! if moved
      moved
    end

    def valid_drop_request?
      drop_params[:list_type] == sortable_list_type &&
        unscoped_list_id? &&
        drop_params.key?(:prev_id)
    end

    # The raw param is checked because permit cannot tell an absent
    # value from a filtered-out array or hash.
    def unscoped_list_id?
      params[:list_id].nil? || params[:list_id] == ""
    end

    def drop_params
      @drop_params ||= params.permit(:list_type, :list_id, :prev_id)
    end

    def sortable_list_type
      ::Type::PdfExportTemplates::SORTABLE_LIST_TYPE
    end

    def render_404_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t(:notice_file_not_found))
      respond_with_turbo_streams(status: :not_found)
    end

    def render_readonly_error
      message = I18n.t("types.edit.export_configuration.templates.readonly_error")

      if request.format.turbo_stream?
        render_error_flash_message_via_turbo_stream(message:)
        respond_with_turbo_streams(status: :forbidden)
      else
        redirect_to edit_variant_pdf_export_template_index_path(variant_scope_project, @variant), alert: message
      end
    end

    def find_type
      @type = ::Type.find(params.expect(:type_id))
    end

    def addressed_type = @type

    def find_variant
      @variant = addressed_variant(among: @type.variants)
    end

    def find_template
      @template = @variant.pdf_export_templates.find(params.expect(:id))
    end
  end
end
