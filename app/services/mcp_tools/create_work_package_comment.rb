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
  class CreateWorkPackageComment < Base
    default_title "Create work package comment"
    default_description "Add a comment to a work package."

    name "create_work_package_comment"
    annotations read_only: false, idempotent: false, destructive: false

    input_schema(
      additionalProperties: false,
      required: %i[work_package_id comment],
      properties: {
        work_package_id: {
          type: :number,
          description: "The ID of the work package to which a comment shall be added."
        },
        comment: {
          type: :string,
          description: "The comment text to be added."
        },
        internal: {
          type: :boolean,
          description: "Whether the comment should only be visible to users with the permission to read internal comments. " \
                       "Default: false"
        }
      }
    )

    def call(work_package_id:, comment:, internal: false)
      work_package = WorkPackage.visible(current_user).find_by(id: work_package_id)
      return Failure("The given work package could not be found.") if work_package.nil?

      result = AddWorkPackageNoteService.new(user: current_user, work_package:).call(comment, send_notifications: true, internal:)

      format_result(result)
    end

    def format_result(result)
      if result.success?
        Success(API::V3::Activities::ActivityRepresenter.create(result.result, current_user:))
      else
        Failure(result.message)
      end
    end
  end
end
