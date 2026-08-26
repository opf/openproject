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
  class CreateWorkPackageRelation < Base
    default_title "Create work package relation"
    default_description "Create a new relation between two work packages."

    name "create_work_package_relation"
    annotations read_only: false, idempotent: false, destructive: false

    input_schema(
      additionalProperties: false,
      required: %i[from_work_package_id to_work_package_id],
      properties: {
        from_work_package_id: {
          type: :number,
          description: "The work package that acts as the origin for the relation."
        },
        to_work_package_id: {
          type: :number,
          description: "The work package that acts as the target for the relation."
        },
        type: {
          type: :string,
          description: "The kind of relation that shall be created. Follows and precedes should only be used " \
                       "when automatic scheduling of work packages is desired.",
          enum: %w[
            relates
            duplicates
            duplicated
            blocks
            blocked
            precedes
            follows
            includes
            partof
            requires
            required
          ]
        },
        description: {
          type: :string,
          description: "A descriptive text for the relation."
        },
        lag: {
          type: :number,
          description: "The lag in days between closing of `from` and start of `to`. " \
                       "Follows and precedes relations will update work package scheduling accordingly."
        }
      }
    )

    private

    def call(from_work_package_id:, to_work_package_id:, type: "relates", description: nil, lag: nil)
      from = WorkPackage.visible(current_user).find_by(id: from_work_package_id)
      to = WorkPackage.visible(current_user).find_by(id: to_work_package_id)
      return Failure("The given work package could not be found.") if from.nil? || to.nil?

      result = Relations::CreateService.new(user: current_user).call(
        from:,
        to:,
        relation_type: type,
        description:,
        lag:
      )

      format_result(result)
    end

    def format_result(result)
      if result.success?
        Success(API::V3::Relations::RelationRepresenter.create(result.result, current_user:))
      else
        Failure(result.message)
      end
    end
  end
end
