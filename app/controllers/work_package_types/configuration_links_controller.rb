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
  # "Switch to linked mode" / "Change source type" on a type's configuration
  # tabs: the source-picker dialog, the danger confirmation (whose wording
  # depends on whether the type is currently Independent or Linked), and the
  # switch itself. The reverse switch back to Independent is handled here too.
  # Built to mirror ConfigurationCopiesController.
  class ConfigurationLinksController < BaseTabController
    include SubtypesFeature
    include OpTurbo::ComponentStream

    before_action :require_subtypes_feature
    before_action :require_valid_aspect

    current_menu_item do
      :types
    end

    def dialog
      respond_with_dialog ConfigurationLinks::DialogComponent.new(type: @type, aspect:)
    end

    # The source picker's submit: swaps the picker for the danger confirmation.
    def confirm
      if source.nil?
        render_error_flash_message_via_turbo_stream(message: t("types.edit.reuse_mode.linked.invalid_source"))
      else
        close_dialog_via_turbo_stream("##{ConfigurationLinks::DialogComponent::DIALOG_ID}")
        dialog_via_turbo_stream(component: ConfigurationLinks::ConfirmDialogComponent.new(type: @type, aspect:, source:))
      end

      respond_with_turbo_streams
    end

    def switch
      result = SwitchToLinkedModeService.new(type: @type, aspect:).call(source:)

      close_dialog_via_turbo_stream("##{ConfigurationLinks::ConfirmDialogComponent::DIALOG_ID}")

      respond_to_switch(result)

      respond_with_turbo_streams
    end

    # Switch back to Independent, adopting the current source's config first.
    # TODO: this direct switch is a stopgap. It will be replaced by a modal
    # confirmation process (source-less danger confirmation) mirroring the
    # switch-to-linked flow, so the user acknowledges the override first.
    def independent
      result = SwitchToIndependentModeService.new(type: @type, aspect:, user: current_user).call(source:)

      respond_to_switch(result)

      respond_with_turbo_streams
    end

    private

    def aspect = params[:aspect]

    def source
      return @source if defined?(@source)

      @source = Type.global.find_by(id: params[:source_id])
    end

    def respond_to_switch(result)
      if result.success?
        render_success_flash_message_via_turbo_stream(message: t("types.edit.reuse_mode.linked.success"))
        dispatch_event_via_turbo_stream(
          ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME,
          detail: { type_id: @type.id, aspect: }
        )
      else
        render_error_flash_message_via_turbo_stream(message: result.errors.full_messages.to_sentence)
      end
    end

    def require_valid_aspect
      render_404 unless Type::ConfigurationLink::ASPECTS.include?(aspect)
    end
  end
end
