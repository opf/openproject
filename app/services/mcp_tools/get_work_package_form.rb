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
  class GetWorkPackageForm < Base
    default_title "Get work package form"
    default_description "Describes a work package for creating or updating it. Pass project_id and type_id for a new " \
                        "work package, or work_package_id for an existing one. Returns the default or current values, " \
                        "including the description template of a new work package, and the writable fields with their " \
                        "types, required flags and allowed values. Call this before create_work_package or " \
                        "update_work_package."

    name "get_work_package_form"
    annotations read_only: true, idempotent: true, destructive: false

    input_schema(
      additionalProperties: false,
      properties: {
        project_id: {
          type: "number",
          description: "The ID of the project the work package will be created in. Required together with type_id " \
                       "when describing a new work package."
        },
        type_id: {
          type: "number",
          description: "The ID of the work package type. Required when describing a new work package. Together with " \
                       "work_package_id, describes the existing work package changed to this type."
        },
        work_package_id: {
          type: %w[string number],
          description: "The identifier of an existing work package. Describes it for an update instead of a new work " \
                       "package."
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

    def call(project_id: nil, type_id: nil, work_package_id: nil)
      if work_package_id && project_id.nil?
        update_form(work_package_id, type_id)
      elsif project_id && type_id && work_package_id.nil?
        create_form(project_id, type_id)
      else
        Failure("Pass project_id and type_id for a new work package, or work_package_id for an existing one. " \
                "Add type_id to work_package_id to describe a type change.")
      end
    end

    private

    def create_form(project_id, type_id)
      project = Project.visible(current_user).find_by(id: project_id)
      return Failure("The given project could not be found.") if project.nil?
      return Failure("You are not allowed to create work packages in this project.") unless can_add_work_packages?(project)

      form(WorkPackage.new(project:), type_id, WorkPackages::CreateContract, API::V3::WorkPackages::CreateFormRepresenter)
    end

    def update_form(work_package_id, type_id)
      work_package = WorkPackage.visible(current_user).find_by_display_id(work_package_id)
      return Failure("The given work package could not be found.") if work_package.nil?
      return Failure("You are not allowed to edit this work package.") unless can_update?(work_package)

      form(work_package, type_id, WorkPackages::UpdateContract, API::V3::WorkPackages::UpdateFormRepresenter)
    end

    def form(work_package, type_id, contract_class, representer)
      type = type_id && work_package.project.enabled_types.find_by(id: type_id)
      return Failure("The given type is not enabled in this project.") if type_id && type.nil?

      work_package = WorkPackages::SetAttributesService
                       .new(user: current_user, model: work_package, contract_class:)
                       .call({ type: }.compact)
                       .result

      Success(representer.new(work_package, current_user:))
    end

    def can_add_work_packages?(project)
      current_user.allowed_in_project?(:add_work_packages, project)
    end

    def can_update?(work_package)
      WorkPackages::UpdateContract.update_allowed?(user: current_user, work_package:)
    end
  end
end
