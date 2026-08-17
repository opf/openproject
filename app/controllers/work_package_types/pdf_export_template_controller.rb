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

module WorkPackageTypes
  class PdfExportTemplateController < ApplicationController
    include AddressesVariant
    include OpTurbo::ComponentStream

    layout "admin"

    before_action :require_admin
    before_action :find_type, only: %i[edit toggle drop enable_all disable_all update_artefact_export]
    before_action :find_variant, only: %i[edit toggle drop enable_all disable_all update_artefact_export]
    before_action :find_template, only: %i[toggle drop]

    current_menu_item do
      :types
    end

    def edit; end

    def update_artefact_export
      mode = params.dig(:type, :artefact_export_mode)
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

    def drop
      return render_404_turbo_stream if @template.nil?

      @variant.pdf_export_templates.move(@template.id, params[:position].to_i - 1) # drop index starts at 1
      @variant.save!
      respond_to_with_turbo_streams
    end

    protected

    def respond_section_with_turbo_streams
      replace_via_turbo_stream(
        component: ::WorkPackageTypes::ExportTemplateListComponent.new(variant: @variant)
      )
      respond_to_with_turbo_streams
    end

    def render_404_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t(:notice_file_not_found))
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
