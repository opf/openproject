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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpTools
  class UpdateWorkPackage < Base
    default_title "Update work package"
    default_description "Updates a work package in-place."

    name "update_work_package"
    annotations read_only: false, idempotent: true, destructive: false

    input_schema(
      additionalProperties: false,
      required: %w[id data],
      properties: {
        id: {
          type: :number,
          description: "The ID of the work package that shall be updated."
        },
        data: {
          type: %w[object],
          description: "JSON Representation of the work package to be updated. Only attributes that shall be changed need " \
                       "to be included. The format is the same as accepted by APIv3.",
          required: %w[lockVersion],
          properties: {
            lockVersion: {
              type: :number,
              description: "The lock version as indicated by the work package when reading it. This value is used for " \
                           "optimistic locking, if a change is rejected because of a conflict, " \
                           "re-read the work package and apply changes based on its new state."
            },
            _links: {
              description: "Contains related resources, such as projects, statuses, types, etc. They are represented as links, " \
                           "i.e. objects with an 'href' property."
            }
          }
        }
      }
    )

    def call(id:, data:)
      work_package = WorkPackage.visible(current_user).find_by(id:)
      return Failure("The given work package could not be found.") if work_package.nil?

      attributes = parse_work_package(data).on_failure { |result| return Failure(result.message) }.result
      result = WorkPackages::UpdateService.new(user: current_user, model: work_package).call(**attributes)

      format_result(result)
    end

    private

    def parse_work_package(data)
      ::API::V3::WorkPackages::ParseParamsService.new(current_user, model: WorkPackage).call(data.deep_stringify_keys)
    end

    def format_result(result)
      if result.success?
        Success(API::V3::WorkPackages::WorkPackageRepresenter.create(result.result, current_user:))
      else
        Failure(result.message)
      end
    end
  end
end
