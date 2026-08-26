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
  class ListWorkPackageRelations < SearchTool
    default_title "List work package relations"
    default_description "List relations of the given work package towards other work packages."

    name "list_work_package_relations"
    annotations read_only: true, idempotent: true, destructive: false

    input_schema(
      additionalProperties: false,
      required: %i[work_package_id],
      properties: {
        work_package_id: {
          type: :number,
          description: "The ID of the work package whose relations shall be listed."
        }
      }
    )

    def scope_param_names
      %i[work_package_id]
    end

    def base_scope(work_package_id:)
      work_package = WorkPackage.visible(current_user).find_by(id: work_package_id)
      return Failure("Can't find given work package.") if work_package.nil?

      Success(
        work_package
          .relations
          .visible(current_user)
          .includes(::API::V3::Relations::RelationCollectionRepresenter.to_eager_load)
          .to_a
      )
    end

    def format_item(item)
      ::API::V3::Relations::RelationRepresenter.new(item, current_user:)
    end
  end
end
