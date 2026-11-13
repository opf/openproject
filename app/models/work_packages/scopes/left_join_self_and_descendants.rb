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

module WorkPackages::Scopes::LeftJoinSelfAndDescendants
  extend ActiveSupport::Concern

  class_methods do
    def left_join_self_and_descendants(work_package = nil)
      joins(join_descendants(work_package).join_sources)
    end

    # Sums +expression+ over the joined descendants that +user+ may see.
    #
    # The visibility check has to stay in the aggregate rather than the join condition: there it
    # matches most of the work package table, leaving PostgreSQL unable to bound the descendants
    # by the hierarchy, so it scans all work packages once per aggregate.
    def sum_over_visible_descendants(user, expression)
      "SUM(CASE WHEN #{allowed_to_view_work_packages(user).to_sql} THEN #{expression} END)"
    end

    # The alias the descendants are joined under, for callers adding their own conditions on them.
    def wp_descendants_table
      arel_table.alias("descendants")
    end

    private

    def join_descendants(work_package)
      arel_table
        .outer_join(hierarchies_table)
        .on(hierarchies_join_condition(work_package))
        .outer_join(wp_descendants_table)
        .on(self_or_descendant_condition)
    end

    def hierarchy_of_wp_condition
      arel_table[:id].eq(hierarchies_table[:ancestor_id])
    end

    def hierarchies_join_condition(work_package)
      if work_package
        hierarchy_of_wp_condition
          .and(arel_table[:id].eq(work_package.id))
      else
        hierarchy_of_wp_condition
      end
    end

    def allowed_to_view_work_packages(user)
      wp_descendants_table[:project_id].in(Project.allowed_to(user, :view_work_packages).select(:id).arel).or(
        wp_descendants_table[:id].in(WorkPackage.visible(user).select(:id).arel)
      )
    end

    def self_or_descendant_condition
      hierarchies_table[:descendant_id].eq(wp_descendants_table[:id])
    end

    def hierarchies_table
      WorkPackageHierarchy.arel_table
    end
  end
end
