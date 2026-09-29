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
  class CreateWorkPackage < Base
    default_title "Create work package"
    default_description "Create a new work package."

    name "create_work_package"
    annotations read_only: false, idempotent: false, destructive: false

    input_schema(
      additionalProperties: false,
      required: %i[data],
      properties: {
        data: {
          type: %w[object],
          description: "JSON Representation of the work package to be created. The format is the same as accepted by APIv3.",
          properties: {
            _links: {
              description: "Contains related resources, such as projects, statuses, types, etc. They are represented as links, " \
                           "i.e. objects with an 'href' property."
            }
          }
        }
      }
    )

    def call(data:)
      attributes = parse_work_package(data).on_failure { |result| return Failure(result.message) }.result

      result = WorkPackages::CreateService.new(user: current_user).call(**attributes)

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
