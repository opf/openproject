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

module ProjectCustomFieldProjectMappings
  class BulkCreateService < ::BulkServices::ProjectMappings::BaseCreateService
    def initialize(user:, projects:, model:, include_sub_projects: false)
      mapping_context = ::BulkServices::ProjectMappings::MappingContext.new(
        mapping_model_class: ProjectCustomFieldProjectMapping,
        model:,
        projects:,
        model_foreign_key_id:,
        include_sub_projects:
      )
      super(user:, mapping_context:)
    end

    protected

    def after_perform(service_result, _params)
      super.tap do
        recalculate_values(service_result)
      end
    end

    def recalculate_values(service_result)
      mappings = service_result.result

      mappings.each do |mapping|
        project = mapping.project

        affected_cfs = project.available_custom_fields.affected_calculated_fields([mapping.custom_field_id])

        project.calculate_custom_fields(affected_cfs)

        project.save if project.changed_for_autosave?
      end
    end

    private

    def permission = :select_project_custom_fields
    def model_foreign_key_id = :custom_field_id
  end
end
