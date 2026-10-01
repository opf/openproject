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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Backlogs
  class WorkPackageSprintSelect < Queries::WorkPackages::Selects::WorkPackageSelect
    include WorkPackageSelectConcern

    attr_reader :project

    SORT_ORDER = %w[visible_sprints.name
                    visible_sprints.start_date
                    visible_sprints.finish_date].freeze

    def initialize(project = nil)
      @project = project

      # Cannot use `association` here since that will break our custom GROUP BY
      super(:sprint,
            sortable: SORT_ORDER,
            groupable_join: sprint_join_with_permissions,
            groupable: group_by_statement)
    end

    def sortable_join_statement(_query)
      sprint_join_with_permissions
    end

    def group_by_statement = "visible_sprints.id"

    private

    # Custom outer join to ensure that sprints the user cannot view are treated like
    # they are not there at all. Without this, group counts would not match the listed
    # work packages.
    #
    # Two conditions gate the join:
    # 1. The sprint must be in the `visible_sprints` subquery (permission-filtered).
    # 2. The work package's own project must be one where the user has :view_sprints
    #    directly. Without this second condition, a sprint that is shared *to*
    #    project_receiving could leak into the sort/group for work packages that live in
    #    the sharer project itself, because `sprint_source_for` transitively includes the
    #    sharer when the user only has permission in the receiver.
    def sprint_join_with_permissions
      <<~SQL.squish
        LEFT OUTER JOIN (
          #{visible_sprints.to_sql}
        ) AS visible_sprints
        ON visible_sprints.id = work_packages.sprint_id
        AND work_packages.project_id IN (#{projects_with_view_sprints.select(:id).to_sql})
      SQL
    end

    def visible_sprints
      scope = if project
                Sprint.for_project(project)
              else
                Sprint
              end

      scope.visible
    end
  end
end
