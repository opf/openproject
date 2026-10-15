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
  # Counts work packages with the filters of search_work_packages, as a total or per value of
  # one field. One call answers "how many", where a search would need a page per status.
  class CountWorkPackages < SearchTool
    GROUPS = {
      "status" => [:status, "statuses.name"],
      "type" => [:type, "types.name"],
      "priority" => [:priority, "enumerations.name"],
      "project" => [:project, "projects.name"]
    }.freeze
    GROUP_BY = (GROUPS.keys + ["assignee"]).freeze

    default_title "Count work packages"
    default_description "Count the work packages matching all of the passed input parameters. Parameters not passed " \
                        "are ignored. Without group_by, only the total is returned. With group_by, the count per " \
                        "value of that field is returned as well. Use this tool, not search_work_packages, to " \
                        "answer questions about numbers."

    name "count_work_packages"
    annotations read_only: true, idempotent: true, destructive: false

    class << self
      delegate :filters, to: "McpTools::SearchWorkPackages"
    end

    input_schema(
      additionalProperties: false,
      properties: SearchWorkPackages.input_schema[:properties].except(:page, :level_of_detail).merge(
        group_by: {
          type: "string",
          enum: GROUP_BY,
          description: "Count per value of this field."
        }
      )
    )

    private

    def call(group_by: nil, **filters)
      base_scope.bind do |scope|
        filtered = apply_filters(scope, filters)
        result = { total: filtered.count }
        return Success(result) if group_by.blank?

        Success(result.merge(group_by:, groups: groups(filtered, group_by)))
      end
    end

    def base_scope
      Success(WorkPackage.visible(current_user))
    end

    def groups(scope, group_by)
      counts = if group_by == "assignee"
                 assignee_counts(scope)
               else
                 association, column = GROUPS.fetch(group_by)
                 scope.left_joins(association).group(column).count
               end

      counts.map { |name, count| { name: name || "(none)", count: } }.sort_by { |group| -group[:count] }
    end

    # Names only principals that the user can see.
    def assignee_counts(scope)
      counts = scope.group(:assigned_to_id).count
      names = visible_names(counts.keys.compact)

      counts.each_with_object(Hash.new(0)) do |(id, count), result|
        result[id && names.fetch(id, "(not visible)")] += count
      end
    end

    def visible_names(ids)
      Principal.visible(current_user).where(id: ids).to_h { |principal| [principal.id, principal.name] }
    end
  end
end
