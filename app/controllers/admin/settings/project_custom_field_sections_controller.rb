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
  class ProjectCustomFieldSectionsController < ::Admin::SettingsController
    include OpTurbo::ComponentStream
    include Admin::Settings::ProjectCustomFields::ComponentStreams

    before_action :set_project_custom_field_section, only: %i[move drop]

    def create
      @project_custom_field_section = ProjectCustomFieldSection.new(
        name: project_custom_field_section_params[:name],
        position: 1 # show new sections at the top of the list, otherwise might not be visible to user
      )

      if @project_custom_field_section.save
        update_header_via_turbo_stream # required to closed the dialog
        update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)
      else
        update_section_dialog_body_form_via_turbo_stream(project_custom_field_section: @project_custom_field_section)
      end

      respond_with_turbo_streams
    end

    def update
      @project_custom_field_section = ProjectCustomFieldSection.find(params[:id])

      if @project_custom_field_section.update(project_custom_field_section_params)
        update_section_via_turbo_stream(project_custom_field_section: @project_custom_field_section)
      else
        update_section_dialog_body_form_via_turbo_stream(project_custom_field_section: @project_custom_field_section)
      end

      respond_with_turbo_streams
    end

    def destroy
      @project_custom_field_section = ProjectCustomFieldSection.find(params[:id])

      if @project_custom_field_section.destroy
        update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)
      end

      respond_with_turbo_streams
    end

    def move
      @project_custom_field_section.move_to = params[:move_to]&.to_sym

      if @project_custom_field_section.save
        update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)
      end

      respond_with_turbo_streams
    end

    def drop
      @project_custom_field_section.insert_at(params[:position].to_i)

      update_sections_via_turbo_stream(project_custom_field_sections: ProjectCustomFieldSection.all)

      respond_with_turbo_streams
    end

    private

    def set_project_custom_field_section
      @project_custom_field_section = ProjectCustomFieldSection.find(params[:id])
    end

    def project_custom_field_section_params
      params.require(:project_custom_field_section).permit(:name)
    end
  end
end
