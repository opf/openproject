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

module McpTools
  class GetWorkPackageSchema < Base
    default_title "Get work package schema"
    default_description "Describes a new work package of the given type in the given project. Returns the default " \
                        "values, including the description template, and the writable fields with their types, required " \
                        "flags and allowed values. Call this before create_work_package."

    name "get_work_package_schema"
    annotations read_only: true, idempotent: true, destructive: false

    input_schema(
      additionalProperties: false,
      required: %i[project_id type_id],
      properties: {
        project_id: {
          type: "number",
          description: "The ID of the project the work package will be created in."
        },
        type_id: {
          type: "number",
          description: "The ID of the work package type."
        }
      }
    )

    output_filter McpOutputFilters::RemoveFormattableHtml.new
    output_filter McpOutputFilters::RemoveLinks.new(%w[self validate previewMarkup commit configureForm])
    output_filter McpOutputFilters::RemoveEmbeddedAllowedValues.new
    output_filter McpOutputFilters::RemoveReadOnlySchemaProperties.new
    output_filter McpOutputFilters::RemoveDeprecatedSchemaProperties.new
    output_filter McpOutputFilters::RemoveInactiveWorkPackageFormFields.new
    output_filter McpOutputFilters::RemoveKeys.new(%w[_dependencies validationErrors])

    def call(project_id:, type_id:)
      project = Project.visible(current_user).find_by(id: project_id)
      return Failure("The given project could not be found.") if project.nil?
      return Failure("You are not allowed to create work packages in this project.") unless can_add_work_packages?(project)

      type = project.enabled_types.find_by(id: type_id)
      return Failure("The given type is not enabled in this project.") if type.nil?

      Success(form_for(project, type))
    end

    private

    def can_add_work_packages?(project)
      current_user.allowed_in_project?(:add_work_packages, project)
    end

    def form_for(project, type)
      work_package = WorkPackages::SetAttributesService
                       .new(user: current_user, model: WorkPackage.new(project:), contract_class: WorkPackages::CreateContract)
                       .call(type:)
                       .result

      API::V3::WorkPackages::CreateFormRepresenter.new(work_package, current_user:)
    end
  end
end
