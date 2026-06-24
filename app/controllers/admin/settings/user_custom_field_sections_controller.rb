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

module Admin::Settings
  class UserCustomFieldSectionsController < ::Admin::SettingsController
    include OpTurbo::ComponentStream
    include Admin::Settings::UserCustomFields::ComponentStreams

    before_action :set_user_custom_field_section, only: %i[update move drop destroy]

    def create
      call = ::UserCustomFieldSections::CreateService.new(user: current_user).call(
        user_custom_field_section_params.merge(position: 1)
      )

      if call.success?
        close_dialog_via_turbo_stream("##{Settings::UserCustomFieldSections::NewSectionDialogComponent::MODAL_ID}")
        update_header_via_turbo_stream(allow_custom_field_creation: allow_custom_field_creation?)
        update_sections_via_turbo_stream(user_custom_field_sections: UserCustomFieldSection.all)
      else
        update_section_dialog_body_form_via_turbo_stream(user_custom_field_section: call.result)
      end

      respond_with_turbo_streams
    end

    def update
      call = ::UserCustomFieldSections::UpdateService.new(user: current_user, model: @user_custom_field_section).call(
        user_custom_field_section_params
      )

      if call.success?
        close_dialog_via_turbo_stream("#user-custom-field-section-dialog#{@user_custom_field_section.id}")
        update_section_via_turbo_stream(user_custom_field_section: call.result)
      else
        update_section_dialog_body_form_via_turbo_stream(user_custom_field_section: call.result)
      end

      respond_with_turbo_streams
    end

    def destroy
      call = ::UserCustomFieldSections::DeleteService.new(user: current_user, model: @user_custom_field_section).call

      if call.success?
        update_header_via_turbo_stream(allow_custom_field_creation: allow_custom_field_creation?)
        update_sections_via_turbo_stream(user_custom_field_sections: UserCustomFieldSection.all)
      else
        render_section_error_via_turbo_stream(call)
      end

      respond_with_turbo_streams
    end

    def move
      call = ::UserCustomFieldSections::UpdateService.new(user: current_user, model: @user_custom_field_section).call(
        move_to: params.expect(:move_to)&.to_sym
      )

      if call.success?
        update_sections_via_turbo_stream(user_custom_field_sections: UserCustomFieldSection.all)
      else
        render_section_error_via_turbo_stream(call)
      end

      respond_with_turbo_streams
    end

    def drop
      call = ::UserCustomFieldSections::UpdateService.new(user: current_user, model: @user_custom_field_section).call(
        position: params[:position].to_i
      )

      if call.success?
        update_header_via_turbo_stream(allow_custom_field_creation: allow_custom_field_creation?)
        update_sections_via_turbo_stream(user_custom_field_sections: UserCustomFieldSection.all)
      else
        render_section_error_via_turbo_stream(call)
      end

      respond_with_turbo_streams
    end

    def new_link
      respond_with_dialog Settings::UserCustomFieldSections::NewSectionDialogComponent.new
    end

    private

    # Show a danger toast with the action's hint (resolved relative to the
    # controller/action), appending the service's error detail (e.g. why a
    # non-empty section cannot be deleted) when present.
    def render_section_error_via_turbo_stream(call)
      message = [t(".error"), call.message].compact_blank.join(" ")
      render_error_flash_message_via_turbo_stream(message:)
    end

    def set_user_custom_field_section
      @user_custom_field_section = UserCustomFieldSection.find(params.expect(:id))
    end

    def allow_custom_field_creation?
      UserCustomFieldSection.any?
    end

    def user_custom_field_section_params
      params.expect(user_custom_field_section: [:name])
    end
  end
end
