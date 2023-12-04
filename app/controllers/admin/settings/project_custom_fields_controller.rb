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

    before_action :set_sections, only: %i[show index edit update move drop]
    before_action :find_custom_field, only: %i(show edit update destroy delete_option reorder_alphabetical move drop)
    before_action :prepare_custom_option_position, only: %i(update create)
    before_action :find_custom_option, only: :delete_option

    def default_breadcrumb
      t(:label_project_attributes_plural)
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

    def edit; end

    def move
      # prototyopical implementation
      # needs refactoring via update service
      @custom_field.move_to = params[:move_to]&.to_sym

      update_sections_via_turbo_stream(project_custom_field_sections: @custom_field_sections)

      respond_with_turbo_streams
    end

    def drop
      # prototyopical implementation
      # needs refactoring via update service
      current_section = @custom_field.project_custom_field_section
      current_section_id = current_section.id
      new_section_id = params[:target_id].to_i

      if current_section_id != new_section_id
        section_changed = true
        old_section = current_section
        current_section = ProjectCustomFieldSection.find(params[:target_id].to_i)
        @custom_field.remove_from_list
        @custom_field.update(project_custom_field_section: current_section)
      end

      @custom_field.insert_at(params[:position].to_i)

      update_section_via_turbo_stream(project_custom_field_section: current_section)

      if section_changed
        update_section_via_turbo_stream(project_custom_field_section: old_section)
      end

      respond_with_turbo_streams
    end

    def destroy
      @custom_field.destroy

      update_section_via_turbo_stream(project_custom_field_section: @custom_field.project_custom_field_section)

      respond_with_turbo_streams
    end

    private

    def edit_path(id:)
      admin_settings_project_custom_field_path(id:)
    end

    def index_path(params = {})
      admin_settings_project_custom_fields_path(**params)
    end

    def set_sections
      @project_custom_field_sections = ProjectCustomFieldSection.all
    end

    def find_custom_field
      @custom_field = ProjectCustomField.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
