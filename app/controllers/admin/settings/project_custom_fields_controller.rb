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
    include OpTurbo::ComponentStream
    include Admin::Settings::ProjectCustomFields::ComponentStreams

    menu_item :project_custom_field_settings

    before_action :set_sections, only: %i[index move drop]
    before_action :set_project_custom_field, only: %i[move drop]

    def default_breadcrumb
      t(:label_project_attributes_plural)
    end

    def index
      respond_to :html
    end

    def move
      mapping = @project_custom_field.project_custom_field_section_mapping
      mapping.move_to = params[:move_to]&.to_sym

      update_sections_via_turbo_stream(sections: @sections)

      respond_with_turbo_streams
    end

    def drop
      mapping = @project_custom_field.project_custom_field_section_mapping

      current_section = @project_custom_field.project_custom_field_section
      current_section_id = current_section.id
      new_section_id = params[:target_id].to_i

      if current_section_id != new_section_id
        section_changed = true
        old_section = current_section
        mapping.remove_from_list
        current_section = ProjectCustomFieldSection.find(params[:target_id].to_i)
        @project_custom_field.project_custom_field_section = current_section
      end

      mapping = @project_custom_field.reload.project_custom_field_section_mapping

      if params[:position] == 'lowest'
        mapping.move_to = :lowest
      else
        mapping.insert_at(params[:position].to_i)
      end

      update_section_via_turbo_stream(section: current_section)

      if section_changed
        update_section_via_turbo_stream(section: old_section)
      end

      respond_with_turbo_streams
    end

    private

    def set_sections
      @sections = ProjectCustomFieldSection.all
    end

    def set_project_custom_field
      @project_custom_field = ProjectCustomField.find(params[:id])
    end
  end
end
