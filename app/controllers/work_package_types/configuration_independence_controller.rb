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
  # "Switch to independent mode" on a type's configuration tabs: the mode-picker
  # dialog, the danger confirmation, and the switch itself, which seeds the
  # configuration from the chosen IndependentMode and severs the link. Built to
  # mirror ConfigurationLinksController.
  class ConfigurationIndependenceController < BaseTabController
    include TypeVariantsFeature
    include OpTurbo::ComponentStream

    before_action :require_type_variants_feature
    before_action :require_valid_aspect

    current_menu_item do
      :types
    end

    def dialog
      respond_with_dialog ConfigurationIndependence::DialogComponent.new(variant: @variant, aspect:)
    end

    # The mode picker's submit: swaps the picker for the danger confirmation.
    def confirm
      if IndependentMode.available?(aspect, mode)
        close_dialog_via_turbo_stream(ConfigurationIndependence::DialogComponent::DIALOG_ID)
        dialog_via_turbo_stream(component: ConfigurationIndependence::ConfirmDialogComponent.new(variant: @variant, aspect:,
                                                                                                 mode:))
      else
        render_error_flash_message_via_turbo_stream(message: t("types.edit.reuse_mode.independent.invalid_mode"))
      end

      respond_with_turbo_streams
    end

    def switch
      result = SwitchToIndependentModeService.new(variant: @variant, aspect:, user: current_user).call(mode:)

      close_dialog_via_turbo_stream(ConfigurationIndependence::ConfirmDialogComponent::DIALOG_ID)

      respond_to_switch(result)

      respond_with_turbo_streams
    end

    private

    def aspect = params[:aspect]

    def mode = params[:mode].presence || IndependentMode::COPY

    def respond_to_switch(result)
      if result.success?
        render_success_flash_message_via_turbo_stream(message: t("types.edit.reuse_mode.independent.success"))
        dispatch_event_via_turbo_stream(
          ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME,
          detail: { type_id: @type.id, aspect: }
        )
      else
        render_error_flash_message_via_turbo_stream(message: result.errors.full_messages.to_sentence)
      end
    end

    def require_valid_aspect
      render_404 unless TypeVariant::ASPECTS.include?(aspect)
    end
  end
end
