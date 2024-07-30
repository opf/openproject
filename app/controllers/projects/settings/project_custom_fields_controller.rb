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

class Projects::Settings::ProjectCustomFieldsController < Projects::SettingsController
  include OpTurbo::ComponentStream
  include Projects::Settings::ProjectCustomFields::ComponentStreams

  menu_item :settings_project_custom_fields

  before_action :eager_load_project_custom_field_data, only: %i[show toggle enable_all_of_section disable_all_of_section]

  before_action :set_project_custom_field_section, only: %i[enable_all_of_section disable_all_of_section]

  def show; end

  def toggle
    call = ProjectCustomFieldProjectMappings::ToggleService
      .new(user: current_user)
      .call(permitted_params.project_custom_field_project_mapping)

    # we don't need to rerender a component as the toggle switch shows the correct state base on a successful response
    if call.success?
      render json: {}, status: :ok
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def enable_all_of_section
    call = bulk_edit_service.call(action: :enable)

    if call.success?
      eager_load_project_custom_field_data # reload mappings

      update_sections_via_turbo_stream # update all sections in order not to mess with stimulus target references
    else
      # TODO: handle error
    end

    respond_with_turbo_streams
  end

  def disable_all_of_section
    call = bulk_edit_service.call(action: :disable)

    if call.success?
      eager_load_project_custom_field_data # reload mappings

      update_sections_via_turbo_stream # update all sections in order not to mess with stimulus target references
    else
      # TODO: handle error
    end

    respond_with_turbo_streams
  end

  private

  def eager_load_project_custom_field_data
    # Load only the sections that have visible custom_fields associated
    @project_custom_field_sections =
      ProjectCustomFieldSection
        .joins(:custom_fields)
        .includes(:custom_fields)
        .merge(ProjectCustomField.visible)
        .group(:id, "custom_fields.id")
        .order(:position, :position_in_custom_field_section)
  end

  def set_project_custom_field_section
    @project_custom_field_section = ProjectCustomFieldSection.find(
      permitted_params.project_custom_field_project_mapping[:custom_field_section_id]
    )
  end

  def bulk_edit_service
    ProjectCustomFieldProjectMappings::BulkUpdateService
      .new(
        user: current_user,
        project: @project,
        project_custom_field_section: @project_custom_field_section
      )
  end
end
