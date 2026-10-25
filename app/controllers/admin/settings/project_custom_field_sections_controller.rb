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

module Admin::Settings
  class ProjectCustomFieldSectionsController < ::Admin::SettingsController
    include OpTurbo::ComponentStream
    include Admin::Settings::ProjectCustomFields::ComponentStreams
    include ::SortableLists::DropRequestValidation

    configure_drop_request list_type: "section", list_id_scoped: false

    before_action :set_project_custom_field_section, only: %i[update move drop destroy]

    def create
      # show new sections at the top of the list, otherwise might not be visible to user
      call = ::ProjectCustomFieldSections::CreateService.new(user: current_user).call(
        project_custom_field_section_params.merge(position: 1)
      )

      if call.success?
        close_dialog_via_turbo_stream(Settings::ProjectCustomFieldSections::NewSectionDialogComponent::MODAL_ID)
        update_header_via_turbo_stream(allow_custom_field_creation: allow_custom_field_creation?)
        update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)
      else
        update_section_dialog_body_form_via_turbo_stream(project_custom_field_section: call.result)
      end

      respond_with_turbo_streams
    end

    def update
      call = ::ProjectCustomFieldSections::UpdateService.new(user: current_user, model: @project_custom_field_section).call(
        project_custom_field_section_params
      )

      if call.success?
        close_dialog_via_turbo_stream("project-custom-field-section-dialog#{@project_custom_field_section.id}")
        update_section_via_turbo_stream(project_custom_field_section: call.result)
      else
        update_section_dialog_body_form_via_turbo_stream(project_custom_field_section: call.result)
      end

      respond_with_turbo_streams
    end

    def destroy
      call = ::ProjectCustomFieldSections::DeleteService.new(user: current_user, model: @project_custom_field_section).call

      if call.success?
        update_header_via_turbo_stream(allow_custom_field_creation: allow_custom_field_creation?)
        update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)
      else
        render_section_error_via_turbo_stream(call)
      end

      respond_with_turbo_streams
    end

    def move
      call = ::ProjectCustomFieldSections::UpdateService.new(user: current_user, model: @project_custom_field_section).call(
        move_to: params[:move_to]&.to_sym
      )

      if call.success?
        update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)
      else
        render_section_error_via_turbo_stream(call)
      end

      respond_with_turbo_streams
    end

    def drop
      moved = valid_drop_request? &&
        @project_custom_field_section.move_after_anchor(drop_params[:prev_id], scope: ProjectCustomFieldSection.all)

      if moved
        update_header_via_turbo_stream(allow_custom_field_creation: allow_custom_field_creation?)
        update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)
        respond_with_turbo_streams
      else
        render_error_flash_message_via_turbo_stream(message: I18n.t(:error_invalid_list_move_anchor))
        respond_with_turbo_streams(status: :unprocessable_entity)
      end
    end

    def new_link
      respond_with_dialog Settings::ProjectCustomFieldSections::NewSectionDialogComponent.new
    end

    private

    # Show a danger toast with the action's hint (resolved relative to the
    # controller/action), appending the service's error detail (e.g. why a
    # non-empty section cannot be deleted) when present.
    def render_section_error_via_turbo_stream(call)
      message = [t(".error"), call.message].compact_blank.join(" ")
      render_error_flash_message_via_turbo_stream(message:)
    end

    def set_project_custom_field_section
      @project_custom_field_section = ProjectCustomFieldSection.find(params.expect(:id))
    end

    def allow_custom_field_creation?
      ProjectCustomFieldSection.any?
    end

    def project_custom_field_section_params
      # Set the sidebar as default
      params.require(:project_custom_field_section)[:overview] ||= CustomFieldSection::OVERVIEW__SIDEBAR_KEY
      params.expect(project_custom_field_section: %i[name overview])
    end
  end
end
