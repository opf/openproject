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
  class ConfigurationCopiesController < BaseTabController
    include TypeVariantsFeature
    include OpTurbo::ComponentStream

    before_action :require_type_variants_feature
    before_action :require_supported_aspect

    current_menu_item do
      :types
    end

    def dialog
      respond_with_dialog ConfigurationCopies::DialogComponent.new(variant: @variant, aspect:)
    end

    # The source picker's submit: swaps the picker for the danger confirmation.
    def confirm
      if source.nil?
        render_error_flash_message_via_turbo_stream(message: t("types.edit.reuse_mode.copy.invalid_source"))
      else
        close_dialog_via_turbo_stream(ConfigurationCopies::DialogComponent::DIALOG_ID)
        dialog_via_turbo_stream(component: ConfigurationCopies::ConfirmDialogComponent.new(variant: @variant, aspect:, source:))
      end

      respond_with_turbo_streams
    end

    def copy
      result = copy_service.call(source:)

      close_dialog_via_turbo_stream(ConfigurationCopies::ConfirmDialogComponent::DIALOG_ID)

      if result.success?
        respond_to_copy_success
      else
        render_error_flash_message_via_turbo_stream(message: result.errors.full_messages.to_sentence)
      end

      respond_with_turbo_streams
    end

    private

    def aspect = params[:aspect]

    def copy_service
      CopyConfiguration.service_for(aspect).new(variant: @variant, user: current_user)
    end

    def respond_to_copy_success
      render_success_flash_message_via_turbo_stream(message: t("types.edit.reuse_mode.copy.success"))
      dispatch_event_via_turbo_stream(
        ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME,
        detail: { type_id: @type.id, aspect: }
      )
    end

    # Scoped here rather than on the record: a copy carries values across and records no source,
    # so there is no foreign key for the model to validate afterwards.
    def source
      return @source if defined?(@source)

      @source = TypeVariant.available_in(@variant.project).find_by(id: params[:source_id])
    end

    def require_supported_aspect
      render_404 unless CopyConfiguration.supported?(aspect)
    end
  end
end
