#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
#

module WorkPackages::Scopes
  module ForScheduling
    extend ActiveSupport::Concern

    class_methods do
      # Fetches all work packages that need to be evaluated for eventual rescheduling after a related (i.e. follows/precedes
      # and hierarchy) work package is modified or created.
      #
      # The SQL relies on a recursive CTE which will fetch all work packages that are connected to the rescheduled work package
      # via relations (follows/precedes and/or hierarchy) either directly or transitively. It will do so by increasing the relation path
      # length one at a time and will stop on that path if the work package evaluated to be added is either:
      # * itself scheduled manually
      # * having all of it's children scheduled manually
      #
      # The children themselves are scheduled manually if all of their children are scheduled manually which repeats itself down to the leaf
      # work packages. So another way of putting it, and that is how the sql statement works, is that a work package is considered to
      # be scheduled manually if *all* of the paths to their leafs have at least one work package that is scheduled manually.
      # For example in case of the hierarchy:
      # A and B <- hierarchy (C is parent of both A and B) - C <- hierarchy - D
      # if A and B are both scheduled manually, C is also scheduled manually and so is D. But if only A is scheduled manually,
      # B, C and D are scheduled automatically.
      #
      # The recursiveness will of course also stop if no more work packages can be added.
      #
      # The work packages can either be connected via a follows relationship, a hierarchy relationship
      # or a combination of both.
      # E.g. in a graph of
      #   A  <- follows - B <- hierarchy (C is parent of B) - C <- follows D
      #
      # D would also be subject to reschedule.
      #
      # At least for hierarchical relationships, we need to follow the relationship in both directions.
      # E.g. in a graph of
      #   A  <- follows - B - hierarchy (B is parent of C) -> C <- follows D
      #
      # D would also be subject to reschedule.
      #
      # That possible switch in direction means that we cannot simply get all possibly affected work packages by one
      # SQL query which the DAG implementation would have allowed us to do otherwise.
      #
      # Currently, we do not rely on DAG for increasing the path length at all. We are still employing it in the check
      # for whether all paths to the leaf have a manually scheduled work package.
      #
      # A further improvement in performance might be reachable by also employing DAG mechanisms to increase the path length.
      #
      # @param work_packages WorkPackage[] A set of work packages for which the set of related work packages that might
      # be subject to reschedule is fetched.
      def for_scheduling(work_packages)
        return none if work_packages.empty?

        sql = <<~SQL
          WITH
            RECURSIVE
            #{paths_sql(work_packages)}

            SELECT id
            FROM to_schedule
            WHERE
              NOT to_schedule.manually
        SQL

        where("id IN (#{sql})")
          .where.not(id: work_packages)
      end

      private

      # This recursive CTE fetches all work packages that are in a direct or transitive follows and/or hierarchy
      # relationship with the provided work package.
      #
      # Hierarchy relationships are followed up as well as down (from and to) but follows relations are only followed
      # from the predecessor to the successor (from_id to to_id).
      #
      # The CTE starts from the provided work package and for that returns:
      #   * the id of the work package
      #   * the information, that the starting work package is not manually scheduled.
      # Whether the starting work package is manually scheduled or in fact automatically scheduled does make no
      # difference but we need those four columns later on.
      #
      # For each recursive step, we return all work packages that are directly related to our current set of work
      # packages by a hierarchy (up or down) or follows relationship (only successors). For each such work package
      # the statement returns:
      #   * id of the work package that is currently at the end of a path.
      #   * the flag indicating whether the added work package is automatically or manually scheduled. This also includes
      #     whether *all* of the added work package's descendants are automatically or manually scheduled.
      #
      # Paths whose ending work package is marked to be manually scheduled are not joined with any more.
      def paths_sql(work_packages)
        values = work_packages.map { |wp| "(#{wp.id}, false)" }.join(', ')

        <<~SQL
             to_schedule (id, manually) AS (
               SELECT * FROM (VALUES#{values}) AS t(id, manually)

               UNION

               SELECT
                 CASE
                   WHEN relations.to_id = to_schedule.id
                   THEN relations.from_id
                   ELSE relations.to_id
                 END id,
                 (work_packages.schedule_manually OR COALESCE(descendants.schedule_manually, false)) manually
               FROM
                 to_schedule
               JOIN
                 relations
                 ON NOT to_schedule.manually
                 AND (#{relations_condition_sql})
                 AND
                   ((relations.to_id = to_schedule.id)
                   OR (relations.from_id = to_schedule.id AND relations.follows = 0))
               LEFT JOIN work_packages
                 ON (CASE
                   WHEN relations.to_id = to_schedule.id
                   THEN relations.from_id
                   ELSE relations.to_id
                   END) = work_packages.id
               LEFT JOIN (
                 SELECT
                   relations.from_id,
                   bool_and(COALESCE(work_packages.schedule_manually, false)) schedule_manually
                 FROM relations relations
                 JOIN work_packages
                 ON
                   work_packages.id = relations.to_id
                   AND relations.follows = 0 AND #{relations_condition_sql(transitive: true)}
                 GROUP BY relations.from_id
          ) descendants ON work_packages.id = descendants.from_id
             )
        SQL
      end

      def relations_condition_sql(transitive: false)
        <<~SQL
          "relations"."relates" = 0 AND "relations"."duplicates" = 0 AND "relations"."blocks" = 0 AND "relations"."includes" = 0 AND "relations"."requires" = 0
            AND (relations.hierarchy + relations.relates + relations.duplicates + relations.follows + relations.blocks + relations.includes + relations.requires #{transitive ? '>' : ''}= 1)
        SQL
      end
    end
  end
end
