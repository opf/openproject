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

class Projects::Settings::ProjectCustomFieldsController < Projects::SettingsController
  include OpTurbo::ComponentStream
  include Projects::Settings::ProjectCustomFields::ComponentStreams

  menu_item :settings_project_custom_fields

  before_action :eager_load_project_custom_field_sections, only: %i[show update]
  before_action :eager_load_project_custom_fields, only: %i[show update]
  before_action :eager_load_project_custom_field_project_mappings, only: %i[show update]

  def show; end

  def update
    mapping = ProjectCustomFieldProjectMapping.find_or_initialize_by(
      project_id: @project.id,
      custom_field_id: params[:project_custom_field_id]
    )

    if mapping.persisted?
      mapping.destroy!
    else
      mapping.save!
    end

    eager_load_project_custom_field_project_mappings # reload mappings

    update_sections_via_turbo_stream

    respond_with_turbo_streams
  end

  private

  def eager_load_project_custom_field_sections
    @project_custom_field_sections = ProjectCustomFieldSection.all.to_a
  end

  def eager_load_project_custom_fields
    @project_custom_fields_grouped_by_section = ProjectCustomField
      .includes(:project_custom_field_section)
      .sort_by { |pcf| pcf.project_custom_field_section.position }
      .group_by(&:custom_field_section_id)
  end

  def eager_load_project_custom_field_project_mappings
    @project_custom_field_project_mappings = ProjectCustomFieldProjectMapping
      .where(project_id: @project.id)
      .to_a
  end
end
