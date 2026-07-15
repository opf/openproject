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
  class WorkPackageBucketSelect < Queries::WorkPackages::Selects::WorkPackageSelect
    include WorkPackageSelectConcern

    attr_reader :project

    def initialize(project = nil)
      @project = project

      # Cannot use `association` here since that will break our custom GROUP BY
      super(:backlog_bucket,
            sortable: %w[visible_buckets.name],
            groupable_join: bucket_join_with_permissions,
            groupable: group_by_statement)
    end

    def sortable_join_statement(_query)
      bucket_join_with_permissions
    end

    def group_by_statement = "visible_buckets.id"

    private

    # Custom outer join to ensure that buckets the user cannot view are treated like
    # they are not there at all. Without this, group counts would not match the listed
    # work packages.
    def bucket_join_with_permissions
      <<~SQL.squish
        LEFT OUTER JOIN (
          #{visible_buckets.to_sql}
        ) AS visible_buckets
        ON visible_buckets.id = work_packages.backlog_bucket_id
        AND work_packages.project_id IN (#{projects_with_view_sprints.select(:id).to_sql})
      SQL
    end

    def visible_buckets
      scope = if project
                BacklogBucket.where(project:)
              else
                BacklogBucket
              end

      scope.visible
    end
  end
end
