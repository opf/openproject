#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  class ProjectCustomFieldsController < ::Admin::SettingsController
    include CustomFields::SharedActions
    include OpTurbo::ComponentStream
    include Admin::Settings::ProjectCustomFields::ComponentStreams

    menu_item :project_custom_fields_settings

    before_action :set_sections, only: %i[show index edit move drop]
    before_action :find_custom_field, only: %i(show edit destroy move drop)

    def show_local_breadcrumb
      false
    end

    def index
      respond_to :html
    end

    def show
      # quick fixing redirect issue from perform_update
      # perform_update is always redirecting to the show action altough configured otherwise
      render :edit
    end

    def new
      @custom_field = ProjectCustomField.new(custom_field_section_id: params[:custom_field_section_id])

      respond_to :html
    end

    def edit
      @project_custom_field_mapping_query = Queries::Projects::ProjectQuery.new(
        name: "project-custom-field-mapping-#{@custom_field.id}"
      ) do |query|
        query.where(:available_project_attributes, "=", [@custom_field.id])
        query.select :name
      end
    end

    def unlink
      # call = ProjectCustomFieldProjectMappings::ToggleService
      #          .new(user: current_user)
      #          .call(permitted_params.project_custom_field_project_mapping)

      project = Project.find(permitted_params.project_custom_field_project_mapping["project_id"])
      remove_via_turbo_stream(
        component: Settings::ProjectCustomFields::ProjectCustomFieldMapping::RowComponent
                     .new(row: [project, 0], table: OpenStruct.new(columns: [], favored_project_ids: [])))

      respond_to_with_turbo_streams(status: true ? :ok : :unprocessable_entity)
    end

    def move
      call = CustomFields::UpdateService.new(user: current_user, model: @custom_field).call(
        move_to: params[:move_to]&.to_sym
      )

      if call.success?
        update_sections_via_turbo_stream(project_custom_field_sections: @project_custom_field_sections)
      else
        # TODO: handle error
      end

      respond_with_turbo_streams
    end

    def drop
      call = ::ProjectCustomFields::DropService.new(user: current_user, project_custom_field: @custom_field).call(
        target_id: params[:target_id],
        position: params[:position]
      )

      if call.success?
        drop_success_streams(call)
      else
        # TODO: handle error
      end

      respond_with_turbo_streams
    end

    def destroy
      @custom_field.destroy

      update_section_via_turbo_stream(project_custom_field_section: @custom_field.project_custom_field_section)

      respond_with_turbo_streams
    end

    private

    def set_sections
      @project_custom_field_sections = ProjectCustomFieldSection
                                         .includes(custom_fields: :project_custom_field_project_mappings)
                                         .all
    end

    def find_custom_field
      @custom_field = ProjectCustomField.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def drop_success_streams(call)
      update_section_via_turbo_stream(project_custom_field_section: call.result[:current_section])
      if call.result[:section_changed]
        update_section_via_turbo_stream(project_custom_field_section: call.result[:old_section])
      end
    end
  end
end
